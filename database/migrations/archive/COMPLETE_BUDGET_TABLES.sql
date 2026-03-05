-- ============================================
-- COMPLETE SQL SCRIPT FOR ALL BUDGET TABLES
-- Run this in your Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. MADRASA INCOME TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS madrasa_income (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  description TEXT NOT NULL,
  rs NUMERIC NULL,
  date DATE NULL,
  section_id BIGINT NULL
);

-- Add section_id if table already exists
ALTER TABLE madrasa_income ADD COLUMN IF NOT EXISTS section_id BIGINT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_madrasa_income_section ON madrasa_income(section_id);
CREATE INDEX IF NOT EXISTS idx_madrasa_income_date ON madrasa_income(date);

-- ============================================
-- 2. MADRASA EXPENDITURE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS madrasa_expenditure (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  description TEXT NOT NULL,
  rs NUMERIC NULL,
  date DATE NULL,
  section_id BIGINT NULL
);

-- Add section_id if table already exists
ALTER TABLE madrasa_expenditure ADD COLUMN IF NOT EXISTS section_id BIGINT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_madrasa_expenditure_section ON madrasa_expenditure(section_id);
CREATE INDEX IF NOT EXISTS idx_madrasa_expenditure_date ON madrasa_expenditure(date);

-- ============================================
-- 3. MASJID INCOME TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS masjid_income (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  description TEXT NOT NULL,
  rs NUMERIC NULL,
  date DATE NULL,
  section_id BIGINT NULL
);

-- Add section_id if table already exists
ALTER TABLE masjid_income ADD COLUMN IF NOT EXISTS section_id BIGINT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_masjid_income_section ON masjid_income(section_id);
CREATE INDEX IF NOT EXISTS idx_masjid_income_date ON masjid_income(date);

-- ============================================
-- 4. MASJID EXPENDITURE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS masjid_expenditure (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  description TEXT NOT NULL,
  rs NUMERIC NULL,
  date DATE NULL,
  section_id BIGINT NULL
);

-- Add section_id if table already exists
ALTER TABLE masjid_expenditure ADD COLUMN IF NOT EXISTS section_id BIGINT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_masjid_expenditure_section ON masjid_expenditure(section_id);
CREATE INDEX IF NOT EXISTS idx_masjid_expenditure_date ON masjid_expenditure(date);

-- ============================================
-- 5. SECTIONS TABLE (for organizing budget)
-- ============================================
CREATE TABLE IF NOT EXISTS sections (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  institution TEXT NOT NULL, -- 'madrasa' or 'masjid'
  type TEXT NOT NULL -- 'income' or 'expenditure'
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sections_institution ON sections(institution);
CREATE INDEX IF NOT EXISTS idx_sections_type ON sections(type);
CREATE INDEX IF NOT EXISTS idx_sections_inst_type ON sections(institution, type);

-- ============================================
-- VERIFY ALL TABLES
-- ============================================
-- Check madrasa_income columns
SELECT 'madrasa_income' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'madrasa_income'
ORDER BY ordinal_position;

-- Check madrasa_expenditure columns
SELECT 'madrasa_expenditure' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'madrasa_expenditure'
ORDER BY ordinal_position;

-- Check masjid_income columns
SELECT 'masjid_income' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'masjid_income'
ORDER BY ordinal_position;

-- Check masjid_expenditure columns
SELECT 'masjid_expenditure' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'masjid_expenditure'
ORDER BY ordinal_position;

-- Check sections columns
SELECT 'sections' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'sections'
ORDER BY ordinal_position;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Create sample sections
INSERT INTO sections (name, institution, type) VALUES
  ('Student Fees', 'madrasa', 'income'),
  ('Donations', 'madrasa', 'income'),
  ('Zakat', 'madrasa', 'income'),
  ('Teacher Salaries', 'madrasa', 'expenditure'),
  ('Utilities', 'madrasa', 'expenditure'),
  ('Maintenance', 'madrasa', 'expenditure'),
  ('Donations', 'masjid', 'income'),
  ('Zakat', 'masjid', 'income'),
  ('Imam Salary', 'masjid', 'expenditure'),
  ('Utilities', 'masjid', 'expenditure')
ON CONFLICT DO NOTHING;

-- ============================================
-- FINAL VERIFICATION
-- ============================================
SELECT 
  'madrasa_income' as table_name, 
  COUNT(*) as row_count 
FROM madrasa_income
UNION ALL
SELECT 
  'madrasa_expenditure', 
  COUNT(*) 
FROM madrasa_expenditure
UNION ALL
SELECT 
  'masjid_income', 
  COUNT(*) 
FROM masjid_income
UNION ALL
SELECT 
  'masjid_expenditure', 
  COUNT(*) 
FROM masjid_expenditure
UNION ALL
SELECT 
  'sections', 
  COUNT(*) 
FROM sections;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 'All budget tables created/updated successfully!' as status;
