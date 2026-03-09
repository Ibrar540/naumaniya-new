-- Create access_requests table to track user access requests (full or readonly)
CREATE TABLE IF NOT EXISTS access_requests (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('full','readonly')),
  modules JSONB,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP,
  reviewed_by INTEGER REFERENCES users(id),
  reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_access_requests_user_id ON access_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_access_requests_status ON access_requests(status);

-- Prevent duplicate pending requests for the same user, type and modules
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'uq_access_requests_pending_user_type_modules'
  ) THEN
    CREATE UNIQUE INDEX uq_access_requests_pending_user_type_modules
      ON access_requests (user_id, type, COALESCE(modules::text, '[]'))
      WHERE status = 'pending';
  END IF;
END$$;

COMMENT ON TABLE access_requests IS 'Stores access requests (full or readonly) optionally scoped to specific modules';
