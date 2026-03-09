-- Create access_grants table to store granted permissions per user and module
CREATE TABLE IF NOT EXISTS access_grants (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_name VARCHAR(100),
  permission VARCHAR(50) NOT NULL CHECK (permission IN ('readonly','full')),
  granted_by INTEGER REFERENCES users(id),
  granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_access_grants_user_id ON access_grants(user_id);
CREATE INDEX IF NOT EXISTS idx_access_grants_module_name ON access_grants(module_name);

COMMENT ON TABLE access_grants IS 'Stores per-user granted permissions for modules (readonly/full)';
