/**
 * Deta Space Entry Point
 * Serverless-compatible Express app
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const db = require('./config/db');
const { runMigrations } = require('./config/migrate');
const aiEngine = require('./services/aiEngine');
const queryBuilder = require('./services/queryBuilder');
const responseFormatter = require('./services/responseFormatter');
const authRoutes = require('./routes/authRoutes');
const { authenticate, requireActive } = require('./middleware/authMiddleware');
const { denyIfReadonly } = require('./middleware/permissionMiddleware');
const fs = require('fs');
const path = require('path');

// Initialize Express app
const app = express();

// Run SQL migrations from database/migrations (best-effort, idempotent)
(async function runMigrations() {
  try {
    const migrationsDir = path.resolve(__dirname, '../database/migrations');
    if (fs.existsSync(migrationsDir)) {
      const files = fs.readdirSync(migrationsDir).filter(f => f.endsWith('.sql')).sort();
      for (const file of files) {
        const p = path.join(migrationsDir, file);
        try {
          const sql = fs.readFileSync(p, 'utf8');
          console.log(`🔁 Applying migration ${file}`);
          await db.query(sql, []);
          console.log(`✅ Applied migration ${file}`);
        } catch (e) {
          console.error(`❌ Migration ${file} failed:`, e.message || e);
        }
      }
    } else {
      console.log('No migrations directory found at', migrationsDir);
    }
  } catch (err) {
    console.error('Migration runner error:', err.message || err);
  }
})();

// Cleanup old audit logs to keep history size bounded (delete entries older than 30 days)
(async function cleanupOldHistory() {
  try {
    console.log('🔄 Cleaning up audit logs older than 30 days');
    await db.query("DELETE FROM audit_logs WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '30 days')");
    console.log('✅ Old audit logs cleanup complete');
  } catch (e) {
    console.error('Failed to cleanup old audit logs:', e.message || e);
  }
})();

// Middleware
app.use(helmet());
app.use(cors({
  origin: '*', // Deta handles CORS
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  console.log(`📥 ${req.method} ${req.path} - ${new Date().toISOString()}`);
  next();
});

// Auth routes
app.use('/auth', authRoutes);

// Run DB migrations on startup (creates missing tables)
runMigrations().then(() => {
  console.log('✅ Migrations done');
}).catch(err => {
  console.error('❌ Migration failed:', err.message);
});

/**
 * Health check endpoint
 */
app.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'AI Assistant Backend',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

/**
 * Manual migration trigger (run once if tables are missing)
 */
app.get('/run-migrations', async (req, res) => {
  try {
    await runMigrations();
    res.json({ success: true, message: 'Migrations complete' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// If this file is run directly, start an HTTP server for local testing.
if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`🚀 Backend server listening on http://localhost:${port}`);
  });
} else {
  module.exports = app;
}

/**
 * Main AI Query endpoint (Protected - requires authentication)
 */
app.post('/ai-query', authenticate, requireActive, async (req, res) => {
  try {
    const { message } = req.body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message is required and must be a non-empty string'
      });
    }

    if (message.length > 500) {
      return res.status(400).json({
        success: false,
        error: 'Message is too long (max 500 characters)'
      });
    }

    console.log('🤖 Processing query:', message);

    // Parse intent from message
    const intent = await aiEngine.parse(message);
    console.log('📋 Parsed intent:', JSON.stringify(intent, null, 2));

    // If no section detected, try dynamic section detection
    if (!intent.section && intent.module && intent.type !== 'both') {
      const dynamicSection = await detectDynamicSection(message.toLowerCase(), intent.module, intent.type);
      if (dynamicSection) {
        intent.section = dynamicSection;
        console.log('✨ Dynamic section detected:', dynamicSection);
      }
    }

    const { query, params } = queryBuilder.buildQuery(intent);
    console.log('🔍 SQL Query:', query);
    console.log('📊 Parameters:', params);

    const queryResult = await db.query(query, params);
    const response = responseFormatter.formatResponse(intent, queryResult);

    res.json(response);

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: 'Sorry, I could not process your request.'
    });
  }
});

// Example: protect a write endpoint with denyIfReadonly('madrasa')
// (No write endpoints in index.js currently; this shows how to use the middleware)
app.post('/example-protected-write', authenticate, requireActive, denyIfReadonly('madrasa'), async (req, res) => {
  try {
    // Example write handler
    res.json({ success: true, message: 'Write allowed' });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Failed' });
  }
});

/**
 * Dynamic section detection helper
 * Queries database to find sections matching words in the message
 */
async function detectDynamicSection(message, module, type) {
  try {
    // Get all sections for the specific module and type
    const query = `
      SELECT DISTINCT name 
      FROM sections 
      WHERE LOWER(institution) = $1 AND LOWER(type) = $2
      ORDER BY name
    `;
    const result = await db.query(query, [module.toLowerCase(), type.toLowerCase()]);
    
    if (result.rows.length === 0) {
      return null;
    }

    // Extract words from message (remove common words)
    const commonWords = ['give', 'me', 'total', 'income', 'expenditure', 'expense', 
                         'from', 'of', 'in', 'for', 'the', 'a', 'an', 'masjid', 
                         'madrasa', 'مسجد', 'مدرسہ', 'آمدنی', 'خرچ', 'کل'];
    const messageWords = message.split(/\s+/).filter(word => 
      word.length > 1 && !commonWords.includes(word.toLowerCase())
    );

    // Check each section name against message words
    for (const row of result.rows) {
      const sectionName = row.name.toLowerCase();
      
      // Check if section name appears as a whole word or part of message
      if (message.includes(sectionName)) {
        console.log(`🎯 Found section match: "${row.name}" in message`);
        return sectionName;
      }

      // Check if any message word matches section name
      for (const word of messageWords) {
        if (word.toLowerCase() === sectionName || sectionName.includes(word.toLowerCase())) {
          console.log(`🎯 Found section match: "${row.name}" via word "${word}"`);
          return sectionName;
        }
      }
    }

    return null;
  } catch (error) {
    console.error('❌ Error in dynamic section detection:', error);
    return null;
  }
}

/**
 * Get sections endpoint
 */
app.get('/sections', async (req, res) => {
  try {
    const { module, type } = req.query;

    if (!module || !type) {
      return res.status(400).json({
        success: false,
        error: 'Module and type are required'
      });
    }

    // Get sections from sections table filtered by institution and type
    const query = `
      SELECT DISTINCT name 
      FROM sections 
      WHERE institution = $1 AND type = $2
      ORDER BY name
    `;
    const result = await db.query(query, [module, type]);
    
    res.json({
      success: true,
      module,
      type,
      sections: result.rows.map(row => row.name)
    });

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch sections'
    });
  }
});

/**
 * Get years endpoint
 */
app.get('/years', async (req, res) => {
  try {
    const { module, type } = req.query;

    if (!module || !type) {
      return res.status(400).json({
        success: false,
        error: 'Module and type are required'
      });
    }

    const tableName = `${module}_${type}`;
    const query = `
      SELECT DISTINCT EXTRACT(YEAR FROM date) as year 
      FROM ${tableName} 
      WHERE date IS NOT NULL
      ORDER BY year DESC
    `;
    const result = await db.query(query, []);
    
    res.json({
      success: true,
      module,
      type,
      years: result.rows.map(row => parseInt(row.year))
    });

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch years'
    });
  }
});

/**
 * Get AI suggestions based on partial input
 */
app.post('/ai-suggestions', async (req, res) => {
  try {
    const { input } = req.body;

    if (!input || typeof input !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Input is required'
      });
    }

    const lowerInput = input.toLowerCase().trim();

    // Persist input into suggestions_history (upsert: insert or increment occurrences)
    try {
      const upsertQuery = `
        INSERT INTO suggestions_history (input_text, normalized, occurrences)
        VALUES ($1, $2, 1)
        ON CONFLICT (normalized)
        DO UPDATE SET occurrences = suggestions_history.occurrences + 1, updated_at = now()
      `;
      await db.query(upsertQuery, [input, lowerInput]);
    } catch (e) {
      // ignore errors writing suggestions history
      console.error('❌ Failed to persist suggestion:', e.message || e);
    }

    // Query historical suggestions that start with the input or contain it as token
    try {
      const histQuery = `
        SELECT input_text FROM suggestions_history
        WHERE normalized LIKE $1 || '%' OR normalized LIKE '%' || $1 || '%' 
        ORDER BY occurrences DESC, updated_at DESC
        LIMIT 100
      `;
      const histRes = await db.query(histQuery, [lowerInput]);
      const historySuggestions = histRes.rows.map(r => r.input_text);

      // Additionally, generate template suggestions using sections and years (only when helpful)
      const templates = [];
      const currentYear = new Date().getFullYear();

      // Include section names if input mentions them partially
      const sectionsQuery = `SELECT DISTINCT name FROM sections`;
      const sectionsResult = await db.query(sectionsQuery, []);
      const sections = sectionsResult.rows.map(r => r.name);

      // If user typed a short token, return suggestions that start with that token followed by common continuations
      if (lowerInput.length >= 1) {
        // Detect if input contains Urdu/Arabic characters
        const hasUrdu = /[\u0600-\u06FF]/.test(input);

        // Add generic templates matching common query types (English or Urdu)
        if (/\b(total|sum|کل)\b/.test(lowerInput) || lowerInput.length < 6) {
          if (hasUrdu) {
            templates.push(`مسجد کی کل آمدنی ${currentYear}`);
            templates.push(`مسجد کا مالیاتی خلاصہ ${currentYear}`);
          } else {
            templates.push(`Total income of masjid in ${currentYear}`);
            templates.push(`Financial summary of masjid ${currentYear}`);
          }
        }

        // If a section is referenced, add section templates (support Urdu & English)
        for (const s of sections) {
          const sNorm = String(s).toLowerCase().trim();
          // Skip trivial single-letter section names unless explicitly referenced
          if (sNorm.length <= 1) {
            // match explicit patterns like "section A", "شاخ A", "قسم A"
            const explicitRegex = new RegExp('\\b(?:section|shak|شاخ|قسم)\\b\\s*[:]?\\s*' + sNorm + '\\b', 'i');
            if (!explicitRegex.test(input)) continue;
          } else {
            // require a stronger match: either the input contains the section name as a whole word,
            // or the section name contains the input token
            if (!(input.toLowerCase().includes(sNorm) || sNorm.includes(lowerInput))) continue;
          }

          if (hasUrdu) {
            templates.push(`متعلقہ شاخ ${s} کی آمدنی ${currentYear}`);
            templates.push(`${s} کے اخراجات ${currentYear}`);
          } else {
            templates.push(`Total income from ${s} in ${currentYear}`);
            templates.push(`${s} expenditure in ${currentYear}`);
          }
        }
      }

      // Merge history + templates, keep unique and reasonably large (limit 100)
      const merged = [...new Set([...historySuggestions, ...templates])].slice(0, 100);

      return res.json({ success: true, suggestions: merged });
    } catch (e) {
      console.error('❌ Error generating suggestions:', e.message || e);
      return res.status(500).json({ success: false, error: 'Failed to generate suggestions' });
    }

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate suggestions'
    });
  }
});

/**
 * Test database connection
 */
app.get('/test-db', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW() as current_time', []);
    res.json({
      success: true,
      message: 'Database connection successful',
      timestamp: result.rows[0].current_time
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Database connection failed',
      details: error.message
    });
  }
});

/**
 * 404 handler
 */
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

/**
 * Error handler
 */
app.use((err, req, res, next) => {
  console.error('💥 Error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// Export for Deta Space
module.exports = app;
