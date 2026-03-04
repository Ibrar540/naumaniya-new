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

    const lowerInput = input.toLowerCase();
    const suggestions = [];

    // Get available sections
    const sectionsQuery = `SELECT DISTINCT name FROM sections LIMIT 10`;
    const sectionsResult = await db.query(sectionsQuery, []);
    const sections = sectionsResult.rows.map(row => row.name);

    // Get available years
    const yearsQuery = `
      SELECT DISTINCT EXTRACT(YEAR FROM date) as year 
      FROM (
        SELECT date FROM masjid_income
        UNION SELECT date FROM masjid_expenditure
        UNION SELECT date FROM madrasa_income
        UNION SELECT date FROM madrasa_expenditure
      ) AS all_dates
      WHERE date IS NOT NULL
      ORDER BY year DESC
      LIMIT 5
    `;
    const yearsResult = await db.query(yearsQuery, []);
    const years = yearsResult.rows.map(row => parseInt(row.year));

    // Generate suggestions based on input
    const currentYear = new Date().getFullYear();
    const lastYear = currentYear - 1;

    // Total queries
    if (lowerInput.includes('total') || lowerInput.includes('کل')) {
      suggestions.push(`Total income of masjid in ${currentYear}`);
      suggestions.push(`Total expenditure of madrasa in ${currentYear}`);
      if (sections.length > 0) {
        suggestions.push(`Total income from ${sections[0]} in ${currentYear}`);
      }
    }

    // Summary queries
    if (lowerInput.includes('summary') || lowerInput.includes('خلاصہ')) {
      suggestions.push(`Financial summary of masjid ${currentYear}`);
      suggestions.push(`Financial summary of madrasa ${currentYear}`);
    }

    // Compare queries
    if (lowerInput.includes('compare') || lowerInput.includes('موازنہ')) {
      suggestions.push(`Compare masjid income ${lastYear} and ${currentYear}`);
      suggestions.push(`Compare madrasa expenditure ${lastYear} and ${currentYear}`);
    }

    // Net balance queries
    if (lowerInput.includes('balance') || lowerInput.includes('بیلنس')) {
      suggestions.push(`Net balance of masjid in ${currentYear}`);
      suggestions.push(`Net balance of madrasa in ${currentYear}`);
    }

    // Breakdown queries
    if (lowerInput.includes('breakdown') || lowerInput.includes('تفصیل')) {
      suggestions.push(`Breakdown of masjid income ${currentYear}`);
      suggestions.push(`Breakdown of madrasa expenditure ${currentYear}`);
    }

    // Module-specific suggestions
    if (lowerInput.includes('masjid') || lowerInput.includes('مسجد')) {
      suggestions.push(`Total income of masjid in ${currentYear}`);
      suggestions.push(`Total expenditure of masjid in ${currentYear}`);
      suggestions.push(`Financial summary of masjid ${currentYear}`);
    }

    if (lowerInput.includes('madrasa') || lowerInput.includes('مدرسہ')) {
      suggestions.push(`Total income of madrasa in ${currentYear}`);
      suggestions.push(`Total expenditure of madrasa in ${currentYear}`);
      suggestions.push(`Financial summary of madrasa ${currentYear}`);
    }

    // Section-specific suggestions
    for (const section of sections.slice(0, 3)) {
      if (lowerInput.includes(section.toLowerCase())) {
        suggestions.push(`Total income from ${section} in ${currentYear}`);
        suggestions.push(`${section} expenditure in ${currentYear}`);
      }
    }

    // Year-specific suggestions
    for (const year of years.slice(0, 2)) {
      if (lowerInput.includes(year.toString())) {
        suggestions.push(`Total income of masjid in ${year}`);
        suggestions.push(`Financial summary of madrasa ${year}`);
      }
    }

    // Default suggestions if no match
    if (suggestions.length === 0) {
      suggestions.push(`Total income of masjid in ${currentYear}`);
      suggestions.push(`Total expenditure of madrasa in ${currentYear}`);
      suggestions.push(`Financial summary of masjid ${currentYear}`);
      suggestions.push(`Net balance of masjid in ${currentYear}`);
      suggestions.push(`Compare income ${lastYear} and ${currentYear}`);
    }

    // Remove duplicates and limit to 8 suggestions
    const uniqueSuggestions = [...new Set(suggestions)].slice(0, 8);

    res.json({
      success: true,
      suggestions: uniqueSuggestions
    });

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
