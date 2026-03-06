/**
 * Database Connection Module
 * Handles PostgreSQL (Neon) connection using pg library
 */

const { Pool } = require('pg');
require('dotenv').config();

// Serverless-friendly pool: reuse across hot reloads / invocations
// In serverless (Vercel) creating many pools causes "connection terminated due to connection timeout".
// Use a global variable to cache the pool instance.
const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE_URL is not set. Set it in your environment.');
}

let pool;
if (global._naumaniya_pg_pool) {
  pool = global._naumaniya_pg_pool;
} else {
  pool = new Pool({
    connectionString,
    // Many cloud Postgres/Neon endpoints require ssl; enable if connectionString indicates TLS
    ssl: connectionString && connectionString.includes('sslmode=require') ? { rejectUnauthorized: false } : undefined,
    max: parseInt(process.env.PGPOOL_MAX || '10', 10),
    idleTimeoutMillis: parseInt(process.env.PG_IDLE_TIMEOUT || '30000', 10),
    connectionTimeoutMillis: parseInt(process.env.PG_CONN_TIMEOUT || '5000', 10),
  });

  // Keep for debugging
  pool.on('connect', () => {
    console.log('✅ PG pool connected');
  });

  pool.on('error', (err) => {
    console.error('❌ Unexpected database error on idle client:', err);
    // Do not exit the process in serverless; surface the error to caller instead
  });

  global._naumaniya_pg_pool = pool;
}

/**
 * Execute a parameterized query
 * @param {string} text - SQL query with $1, $2 placeholders
 * @param {Array} params - Array of parameter values
 * @returns {Promise} Query result
 */
const query = async (text, params = []) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV !== 'production') {
      console.log('📊 Query executed:', { text, duration, rows: res.rowCount });
    }
    return res;
  } catch (error) {
    console.error('❌ Query error:', error.message || error);
    throw error;
  }
};

/**
 * Get a client from the pool for transactions
 */
const getClient = async () => {
  try {
    const client = await pool.connect();
    return client;
  } catch (err) {
    console.error('❌ Failed to get client from pool:', err.message || err);
    throw err;
  }
};

/** Test DB connection (used by health checks) */
const testConnection = async () => {
  try {
    const r = await query('SELECT NOW() as now');
    return r.rows[0];
  } catch (err) {
    console.error('❌ DB testConnection failed:', err.message || err);
    throw err;
  }
};

module.exports = {
  query,
  getClient,
  pool,
  testConnection,
};
