-- Add missing columns to budget tables
-- Run this SQL in your Supabase SQL Editor

-- Add section_id column to all 4 tables
ALTER TABLE madrasa_income ADD COLUMN IF NOT EXISTS section_id BIGINT;
ALTER TABLE madrasa_expenditure ADD COLUMN IF NOT EXISTS section_id BIGINT;
ALTER TABLE masjid_income ADD COLUMN IF NOT EXISTS section_id BIGINT;
ALTER TABLE masjid_expenditure ADD COLUMN IF NOT EXISTS section_id BIGINT;

-- Rename rs to amount (optional - the app now supports both)
-- Uncomment these lines if you want to rename the column:
-- ALTER TABLE madrasa_income RENAME COLUMN rs TO amount;
-- ALTER TABLE madrasa_expenditure RENAME COLUMN rs TO amount;
-- ALTER TABLE masjid_income RENAME COLUMN rs TO amount;
-- ALTER TABLE masjid_expenditure RENAME COLUMN rs TO amount;

-- Create sections table for organizing income/expenditure
CREATE TABLE IF NOT EXISTS sections (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  institution TEXT NOT NULL, -- 'madrasa' or 'masjid'
  type TEXT NOT NULL -- 'income' or 'expenditure'
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_madrasa_income_section ON madrasa_income(section_id);
CREATE INDEX IF NOT EXISTS idx_madrasa_expenditure_section ON madrasa_expenditure(section_id);
CREATE INDEX IF NOT EXISTS idx_masjid_income_section ON masjid_income(section_id);
CREATE INDEX IF NOT EXISTS idx_masjid_expenditure_section ON masjid_expenditure(section_id);

-- Verify the changes
SELECT 'madrasa_income' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'madrasa_income'
UNION ALL
SELECT 'madrasa_expenditure', column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'madrasa_expenditure'
UNION ALL
SELECT 'masjid_income', column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'masjid_income'
UNION ALL
SELECT 'masjid_expenditure', column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'masjid_expenditure'
ORDER BY table_name, column_name;
