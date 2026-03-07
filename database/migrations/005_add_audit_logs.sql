-- Migration: add audit_logs table to track admin actions
CREATE TABLE IF NOT EXISTS audit_logs (
  id SERIAL PRIMARY KEY,
  actor_id INTEGER NOT NULL,
  actor_name TEXT,
  action TEXT NOT NULL,
  target_user_id INTEGER,
  target_user_name TEXT,
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Optional index to speed up recent lookups
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs (created_at DESC);
