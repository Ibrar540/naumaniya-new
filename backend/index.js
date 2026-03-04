/**
 * Deta Space Entry Point
 * Serverless-compatible Express app
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const db = require('./config/db');
const aiEngine = require('./utils/aiEngine');
const queryBuilder = require('./utils/queryBuilder');
const responseFormatter = require('./utils/responseFormatter');

// Initialize Express app
const app = express();

// Middleware
app.use(helmet());
app.use(cors({
  origin: '*', // Deta handles CORS
  methods: ['GET', 'POST'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  console.log(`📥 ${req.method} ${req.path} - ${new Date().toISOString()}`);
  next();
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
 * Main AI Query endpoint
 */
app.post('/ai-query', async (req, res) => {
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
