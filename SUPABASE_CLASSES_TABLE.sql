-- Create classes table in Supabase
-- Run this SQL in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS classes (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on name for faster searches
CREATE INDEX IF NOT EXISTS idx_classes_name ON classes(name);

-- Create index on status for filtering
CREATE INDEX IF NOT EXISTS idx_classes_status ON classes(status);

-- Enable Row Level Security (optional - if you want to add authentication later)
-- ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (adjust based on your auth requirements)
-- CREATE POLICY "Allow all operations on classes" ON classes
--   FOR ALL
--   USING (true)
--   WITH CHECK (true);
