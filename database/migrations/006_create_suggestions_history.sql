-- Create suggestions_history table to store past inputs for dynamic suggestions
CREATE TABLE IF NOT EXISTS suggestions_history (
  id SERIAL PRIMARY KEY,
  input_text TEXT NOT NULL,
  normalized TEXT NOT NULL,
  occurrences INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_suggestions_normalized ON suggestions_history (normalized);
-- Ensure normalized is unique so we can upsert by normalized value
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_suggestions_normalized'
  ) THEN
    ALTER TABLE suggestions_history ADD CONSTRAINT uq_suggestions_normalized UNIQUE (normalized);
  END IF;
EXCEPTION WHEN undefined_table THEN
  -- ignore
END$$;

-- Upsert helper for inserting or updating suggestion occurrences
-- Use application-side UPSERT via INSERT ... ON CONFLICT (normalized) DO UPDATE
