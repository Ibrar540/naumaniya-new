/**
 * AI Engine - Rule-based NLP for Intent Detection
 * Detects module, type, section, date, and intent from natural language queries
 */

const db = require('../config/db');

class AIEngine {
  constructor() {
    // Keywords for module detection
    this.moduleKeywords = {
      masjid: ['masjid', 'mosque', 'مسجد'],
      madrasa: ['madrasa', 'madrasah', 'مدرسہ', 'مدرسے']
    };

    // Keywords for type detection
    this.typeKeywords = {
      income: ['income', 'revenue', 'earning', 'آمدنی', 'آمدن', 'وصولی'],
      expenditure: ['expenditure', 'expense', 'spending', 'cost', 'خرچ', 'اخراجات', 'خرچہ']
    };

    // Keywords for intent detection
    this.intentKeywords = {
      total: ['total', 'sum', 'کل', 'مجموعی'],
      net_balance: ['net', 'balance', 'profit', 'loss', 'خالص', 'بیلنس'],
      compare: ['compare', 'comparison', 'vs', 'versus', 'موازنہ', 'تقابل'],
      summary: ['summary', 'report', 'overview', 'خلاصہ', 'رپورٹ'],
      breakdown: ['breakdown', 'section', 'wise', 'تفصیل', 'سیکشن']
    };

    // Month names mapping
    this.monthNames = {
      'january': 1, 'jan': 1, 'جنوری': 1,
      'february': 2, 'feb': 2, 'فروری': 2,
      'march': 3, 'mar': 3, 'مارچ': 3,
      'april': 4, 'apr': 4, 'اپریل': 4,
      'may': 5, 'مئی': 5,
      'june': 6, 'jun': 6, 'جون': 6,
      'july': 7, 'jul': 7, 'جولائی': 7,
      'august': 8, 'aug': 8, 'اگست': 8,
      'september': 9, 'sep': 9, 'ستمبر': 9,
      'october': 10, 'oct': 10, 'اکتوبر': 10,
      'november': 11, 'nov': 11, 'نومبر': 11,
      'december': 12, 'dec': 12, 'دسمبر': 12
    };
  }

  /**
   * Main parsing function
   * @param {string} message - User's natural language query
   * @returns {Object} Parsed intent object
   */
  async parse(message) {
    const lowerMessage = message.toLowerCase();
    
    const intent = {
      module: this.detectModule(lowerMessage),
      type: this.detectType(lowerMessage),
      section: await this.detectSection(lowerMessage),
      year: this.detectYear(lowerMessage),
      month: this.detectMonth(lowerMessage),
      intent: this.detectIntent(lowerMessage),
      originalMessage: message
    };

    return intent;
  }

  /**
   * Detect module (masjid or madrasa)
   */
  detectModule(message) {
    for (const [module, keywords] of Object.entries(this.moduleKeywords)) {
      if (keywords.some(keyword => message.includes(keyword))) {
        return module;
      }
    }
    return 'masjid'; // Default to masjid
  }

  /**
   * Detect type (income or expenditure)
   */
  detectType(message) {
    // Check expenditure first (more specific)
    if (this.typeKeywords.expenditure.some(keyword => message.includes(keyword))) {
      return 'expenditure';
    }
    
    if (this.typeKeywords.income.some(keyword => message.includes(keyword))) {
      return 'income';
    }

    // If net balance or summary, return both
    if (message.includes('net') || message.includes('balance') || 
        message.includes('summary') || message.includes('خالص') || 
        message.includes('خلاصہ')) {
      return 'both';
    }

    return 'income'; // Default to income
  }

  /**
   * Detect section name from database
   */
  async detectSection(message) {
    try {
      // Get all unique section names from all tables
      const query = `
        SELECT DISTINCT section_name FROM masjid_income
        UNION
        SELECT DISTINCT section_name FROM masjid_expenditure
        UNION
        SELECT DISTINCT section_name FROM madrasa_income
        UNION
        SELECT DISTINCT section_name FROM madrasa_expenditure
      `;
      
      const result = await db.query(query, []);
      const sections = result.rows.map(row => row.section_name.toLowerCase());

      // Check if any section name is mentioned in the message
      for (const section of sections) {
        if (message.includes(section)) {
          return section;
        }
      }

      return null; // No specific section mentioned
    } catch (error) {
      console.error('Error detecting section:', error);
      return null;
    }
  }

  /**
   * Detect year from message
   */
  detectYear(message) {
    // Match 4-digit year (20xx format)
    const yearMatch = message.match(/\b(20\d{2})\b/);
    if (yearMatch) {
      return parseInt(yearMatch[1]);
    }

    // Handle "last year", "this year"
    const currentYear = new Date().getFullYear();
    
    if (message.includes('last year') || message.includes('پچھلے سال') || message.includes('گزشتہ سال')) {
      return currentYear - 1;
    }
    
    if (message.includes('this year') || message.includes('اس سال') || message.includes('موجودہ سال')) {
      return currentYear;
    }

    return currentYear; // Default to current year
  }

  /**
   * Detect month from message
   */
  detectMonth(message) {
    for (const [monthName, monthNum] of Object.entries(this.monthNames)) {
      if (message.includes(monthName)) {
        return monthNum;
      }
    }

    // Handle "last month"
    if (message.includes('last month') || message.includes('پچھلے مہینے')) {
      const lastMonth = new Date().getMonth(); // 0-indexed
      return lastMonth === 0 ? 12 : lastMonth;
    }

    return null; // No specific month mentioned
  }

  /**
   * Detect intent type
   */
  detectIntent(message) {
    // Check in priority order
    if (this.intentKeywords.compare.some(keyword => message.includes(keyword))) {
      return 'compare';
    }
    
    if (this.intentKeywords.net_balance.some(keyword => message.includes(keyword))) {
      return 'net_balance';
    }
    
    if (this.intentKeywords.summary.some(keyword => message.includes(keyword))) {
      return 'summary';
    }
    
    if (this.intentKeywords.breakdown.some(keyword => message.includes(keyword))) {
      return 'breakdown';
    }
    
    if (this.intentKeywords.total.some(keyword => message.includes(keyword))) {
      return 'total';
    }

    return 'total'; // Default intent
  }
}

module.exports = new AIEngine();
