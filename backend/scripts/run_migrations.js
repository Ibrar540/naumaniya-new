const fs = require('fs');
const path = require('path');
const db = require('../config/db');

async function run() {
  const migrationsDir = path.resolve(__dirname, '../../database/migrations');
  console.log('Migrations dir:', migrationsDir);
  const files = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  if (files.length === 0) {
    console.log('No migration files found.');
    return;
  }

  for (const file of files) {
    const filePath = path.join(migrationsDir, file);
    console.log(`\n--- Running migration: ${file}`);
    const sql = fs.readFileSync(filePath, 'utf8');
    try {
      await db.query(sql, []);
      console.log(`Applied: ${file}`);
    } catch (err) {
      console.error(`Failed to apply ${file}:`, err.message || err);
      process.exitCode = 1;
      return;
    }
  }

  console.log('\nAll migrations applied successfully.');
}

run().catch(err => {
  console.error('Migration runner error:', err);
  process.exit(1);
});
