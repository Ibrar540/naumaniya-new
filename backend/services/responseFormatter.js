/**
 * Response Formatter - Formats query results into user-friendly messages
 * Supports both English and Urdu responses
 */

class ResponseFormatter {
  /**
   * Format response based on intent and query result
   * @param {Object} intent - Parsed intent
   * @param {Object} queryResult - Database query result
   * @returns {Object} Formatted response
   */
  formatResponse(intent, queryResult) {
    const { module, type, section, year, month, intent: intentType } = intent;

    switch (intentType) {
      case 'total':
        return this.formatTotalResponse(intent, queryResult);
      
      case 'net_balance':
        return this.formatNetBalanceResponse(intent, queryResult);
      
      case 'compare':
        return this.formatCompareResponse(intent, queryResult);
      
      case 'summary':
        return this.formatSummaryResponse(intent, queryResult);
      
      case 'breakdown':
        return this.formatBreakdownResponse(intent, queryResult);
      
      default:
        return this.formatTotalResponse(intent, queryResult);
    }
  }

  /**
   * Format total response
   */
  formatTotalResponse(intent, queryResult) {
    const { module, type, section, year, month } = intent;
    const total = queryResult.rows[0]?.total || 0;

    // Build message parts
    const moduleName = this.capitalizeFirst(module);
    const typeName = type === 'income' ? 'Income' : 'Expenditure';
    const sectionPart = section ? ` for ${this.capitalizeFirst(section)}` : '';
    const monthName = month ? this.getMonthName(month) : '';
    const datePart = monthName ? ` in ${monthName} ${year}` : (year ? ` in ${year}` : '');

    const message = `Total ${typeName}${sectionPart} of ${moduleName}${datePart} is ${this.formatCurrency(total)}.`;
    const urduMessage = this.translateToUrdu(message, intent, total);

    return {
      success: true,
      intent: 'total',
      module,
      type,
      section,
      year,
      month,
      result: parseFloat(total),
      message,
      urduMessage,
      data: queryResult.rows[0]
    };
  }

  /**
   * Format net balance response
   */
  formatNetBalanceResponse(intent, queryResult) {
    const { module, year, month } = intent;
    const data = queryResult.rows[0];
    const income = parseFloat(data?.income || 0);
    const expenditure = parseFloat(data?.expenditure || 0);
    const netBalance = parseFloat(data?.net_balance || 0);

    const moduleName = this.capitalizeFirst(module);
    const monthName = month ? this.getMonthName(month) : '';
    const datePart = monthName ? ` for ${monthName} ${year}` : (year ? ` for ${year}` : '');

    const message = `Financial Summary of ${moduleName}${datePart}:\nIncome: ${this.formatCurrency(income)}\nExpenditure: ${this.formatCurrency(expenditure)}\nNet Balance: ${this.formatCurrency(netBalance)}`;

    return {
      success: true,
      intent: 'net_balance',
      module,
      year,
      month,
      result: {
        income,
        expenditure,
        netBalance
      },
      message,
      data
    };
  }

  /**
   * Format comparison response
   */
  formatCompareResponse(intent, queryResult) {
    const { module, type, section } = intent;
    const rows = queryResult.rows;

    if (rows.length === 0) {
      return {
        success: true,
        intent: 'compare',
        result: [],
        message: 'No data available for comparison.'
      };
    }

    const comparison = rows.map(row => ({
      year: parseInt(row.year),
      total: parseFloat(row.total)
    }));

    const moduleName = this.capitalizeFirst(module);
    const typeName = type === 'income' ? 'Income' : 'Expenditure';
    const sectionPart = section ? ` for ${this.capitalizeFirst(section)}` : '';

    let message = `${typeName} Comparison of ${moduleName}${sectionPart}:\n`;
    comparison.forEach(item => {
      message += `${item.year}: ${this.formatCurrency(item.total)}\n`;
    });

    // Calculate difference if we have 2 years
    if (comparison.length === 2) {
      const diff = comparison[0].total - comparison[1].total;
      const percentChange = ((diff / comparison[1].total) * 100).toFixed(2);
      message += `\nChange: ${this.formatCurrency(diff)} (${percentChange}%)`;
    }

    return {
      success: true,
      intent: 'compare',
      module,
      type,
      section,
      result: comparison,
      message,
      data: rows
    };
  }

  /**
   * Format summary response
   */
  formatSummaryResponse(intent, queryResult) {
    const { module, year, month } = intent;
    const data = queryResult.rows[0];
    const income = parseFloat(data?.total_income || 0);
    const expenditure = parseFloat(data?.total_expenditure || 0);
    const netBalance = parseFloat(data?.net_balance || 0);

    const moduleName = this.capitalizeFirst(module);
    const monthName = month ? this.getMonthName(month) : '';
    const datePart = monthName ? ` for ${monthName} ${year}` : (year ? ` for ${year}` : '');

    const message = `📊 Financial Summary of ${moduleName}${datePart}:\n\n` +
                   `💰 Total Income: ${this.formatCurrency(income)}\n` +
                   `💸 Total Expenditure: ${this.formatCurrency(expenditure)}\n` +
                   `📈 Net Balance: ${this.formatCurrency(netBalance)}`;

    return {
      success: true,
      intent: 'summary',
      module,
      year,
      month,
      result: {
        income,
        expenditure,
        netBalance
      },
      message,
      data
    };
  }

  /**
   * Format breakdown response
   */
  formatBreakdownResponse(intent, queryResult) {
    const { module, type, year, month } = intent;
    const rows = queryResult.rows;

    if (rows.length === 0) {
      return {
        success: true,
        intent: 'breakdown',
        result: [],
        message: 'No data available for breakdown.'
      };
    }

    const breakdown = rows.map(row => ({
      section: row.section_name,
      total: parseFloat(row.total),
      count: parseInt(row.count)
    }));

    const moduleName = this.capitalizeFirst(module);
    const typeName = type === 'income' ? 'Income' : 'Expenditure';
    const monthName = month ? this.getMonthName(month) : '';
    const datePart = monthName ? ` for ${monthName} ${year}` : (year ? ` for ${year}` : '');

    let message = `📋 ${typeName} Breakdown of ${moduleName}${datePart}:\n\n`;
    breakdown.forEach((item, index) => {
      message += `${index + 1}. ${this.capitalizeFirst(item.section)}: ${this.formatCurrency(item.total)} (${item.count} entries)\n`;
    });

    const grandTotal = breakdown.reduce((sum, item) => sum + item.total, 0);
    message += `\n💰 Grand Total: ${this.formatCurrency(grandTotal)}`;

    return {
      success: true,
      intent: 'breakdown',
      module,
      type,
      year,
      month,
      result: breakdown,
      message,
      data: rows
    };
  }

  /**
   * Helper: Format currency
   */
  formatCurrency(amount) {
    return `${parseFloat(amount).toLocaleString('en-PK')} PKR`;
  }

  /**
   * Helper: Capitalize first letter
   */
  capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  /**
   * Helper: Get month name
   */
  getMonthName(monthNum) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[monthNum - 1] || '';
  }

  /**
   * Helper: Translate to Urdu (basic translation)
   */
  translateToUrdu(message, intent, total) {
    const { module, type } = intent;
    const moduleName = module === 'masjid' ? 'مسجد' : 'مدرسہ';
    const typeName = type === 'income' ? 'آمدنی' : 'خرچ';
    
    return `${moduleName} کی کل ${typeName}: ${this.formatCurrency(total)}`;
  }

  /**
   * Format error response
   */
  formatError(error, intent) {
    return {
      success: false,
      error: error.message || 'An error occurred',
      intent: intent?.intent || 'unknown',
      message: 'Sorry, I could not process your request. Please try again.'
    };
  }
}

module.exports = new ResponseFormatter();
