-- Migration: add loan table for madrasa (loans only supported for madrasa)
CREATE TABLE IF NOT EXISTS madrasa_loan (
  id SERIAL PRIMARY KEY,
  description TEXT,
  transaction_type TEXT NOT NULL, -- 'loan' or 'payment'
  amount NUMERIC DEFAULT 0,
  action TEXT,
  date DATE,
  section_id INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_madrasa_loan_section_id ON madrasa_loan (section_id);
CREATE INDEX IF NOT EXISTS idx_madrasa_loan_date ON madrasa_loan (date DESC);
