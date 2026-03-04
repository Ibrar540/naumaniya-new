/**
 * Query Builder - Generates safe parameterized SQL queries
 * Builds dynamic SQL based on parsed intent
 */

class QueryBuilder {
  /**
   * Build SQL query based on intent
   * @param {Object} intent - Parsed intent from AIEngine
   * @returns {Object} { query, params }
   */
  buildQuery(intent) {
    const { module, type, section, year, month, intent: intentType } = intent;

    switch (intentType) {
      case 'total':
        return this.buildTotalQuery(module, type, section, year, month);
      
      case 'net_balance':
        return this.buildNetBalanceQuery(module, year, month);
      
      case 'compare':
        return this.buildCompareQuery(module, type, section, year);
      
      case 'summary':
        return this.buildSummaryQuery(module, year, month);
      
      case 'breakdown':
        return this.buildBreakdownQuery(module, type, year, month);
      
      default:
        return this.buildTotalQuery(module, type, section, year, month);
    }
  }

  /**
   * Build total query (SUM of rs)
   */
  buildTotalQuery(module, type, section, year, month) {
    const tableName = `${module}_${type}`;
    let query = `
      SELECT SUM(t.rs) as total 
      FROM ${tableName} t
      LEFT JOIN sections s ON t.section_id = s.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    // Add year filter
    if (year) {
      query += ` AND EXTRACT(YEAR FROM t.date) = $${paramIndex}`;
      params.push(year);
      paramIndex++;
    }

    // Add month filter
    if (month) {
      query += ` AND EXTRACT(MONTH FROM t.date) = $${paramIndex}`;
      params.push(month);
      paramIndex++;
    }

    // Add section filter
    if (section) {
      query += ` AND LOWER(s.name) = $${paramIndex}`;
      params.push(section.toLowerCase());
      paramIndex++;
    }

    return { query, params };
  }

  /**
   * Build net balance query (income - expenditure)
   */
  buildNetBalanceQuery(module, year, month) {
    let incomeQuery = `SELECT COALESCE(SUM(rs), 0) as total FROM ${module}_income WHERE 1=1`;
    let expenseQuery = `SELECT COALESCE(SUM(rs), 0) as total FROM ${module}_expenditure WHERE 1=1`;
    const params = [];
    let paramIndex = 1;

    // Add year filter
    if (year) {
      incomeQuery += ` AND EXTRACT(YEAR FROM date) = $${paramIndex}`;
      expenseQuery += ` AND EXTRACT(YEAR FROM date) = $${paramIndex}`;
      params.push(year);
      paramIndex++;
    }

    // Add month filter
    if (month) {
      incomeQuery += ` AND EXTRACT(MONTH FROM date) = $${paramIndex}`;
      expenseQuery += ` AND EXTRACT(MONTH FROM date) = $${paramIndex}`;
      params.push(month);
      paramIndex++;
    }

    const query = `
      SELECT 
        (${incomeQuery}) as income,
        (${expenseQuery}) as expenditure,
        ((${incomeQuery}) - (${expenseQuery})) as net_balance
    `;

    return { query, params };
  }

  /**
   * Build comparison query (year-wise comparison)
   */
  buildCompareQuery(module, type, section, baseYear) {
    const tableName = `${module}_${type}`;
    const year1 = baseYear || new Date().getFullYear();
    const year2 = year1 - 1;

    let query = `
      SELECT 
        EXTRACT(YEAR FROM t.date) as year,
        SUM(t.rs) as total
      FROM ${tableName} t
      LEFT JOIN sections s ON t.section_id = s.id
      WHERE EXTRACT(YEAR FROM t.date) IN ($1, $2)
    `;
    const params = [year1, year2];

    // Add section filter if specified
    if (section) {
      query += ` AND LOWER(s.name) = $3`;
      params.push(section.toLowerCase());
    }

    query += ` GROUP BY EXTRACT(YEAR FROM t.date) ORDER BY year DESC`;

    return { query, params };
  }

  /**
   * Build summary query (income, expenditure, net balance)
   */
  buildSummaryQuery(module, year, month) {
    let conditions = '1=1';
    const params = [];
    let paramIndex = 1;

    if (year) {
      conditions += ` AND EXTRACT(YEAR FROM date) = $${paramIndex}`;
      params.push(year);
      paramIndex++;
    }

    if (month) {
      conditions += ` AND EXTRACT(MONTH FROM date) = $${paramIndex}`;
      params.push(month);
      paramIndex++;
    }

    const query = `
      SELECT 
        (SELECT COALESCE(SUM(rs), 0) FROM ${module}_income WHERE ${conditions}) as total_income,
        (SELECT COALESCE(SUM(rs), 0) FROM ${module}_expenditure WHERE ${conditions}) as total_expenditure,
        (SELECT COALESCE(SUM(rs), 0) FROM ${module}_income WHERE ${conditions}) - 
        (SELECT COALESCE(SUM(rs), 0) FROM ${module}_expenditure WHERE ${conditions}) as net_balance
    `;

    return { query, params };
  }

  /**
   * Build breakdown query (section-wise breakdown)
   */
  buildBreakdownQuery(module, type, year, month) {
    const tableName = `${module}_${type}`;
    let query = `
      SELECT 
        s.name as section_name,
        SUM(t.rs) as total,
        COUNT(*) as count
      FROM ${tableName} t
      LEFT JOIN sections s ON t.section_id = s.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (year) {
      query += ` AND EXTRACT(YEAR FROM t.date) = $${paramIndex}`;
      params.push(year);
      paramIndex++;
    }

    if (month) {
      query += ` AND EXTRACT(MONTH FROM t.date) = $${paramIndex}`;
      params.push(month);
      paramIndex++;
    }

    query += ` GROUP BY s.name ORDER BY total DESC`;

    return { query, params };
  }
}

module.exports = new QueryBuilder();
