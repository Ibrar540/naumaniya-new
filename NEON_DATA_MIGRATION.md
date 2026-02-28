# Neon Data Migration - Export & Import Guide

## Step 1: Export Data from Supabase

### Option A: Using Supabase Dashboard (Easiest)
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Table Editor
4. For each table, click the "..." menu → Export as CSV
5. Download CSV files for:
   - students
   - teachers
   - sections
   - classes
   - madrasa_income
   - madrasa_expenditure
   - masjid_income
   - masjid_expenditure

### Option B: Using SQL (More Complete)
Run these queries in Supabase SQL Editor and save results:

```sql
-- Export students
COPY (SELECT * FROM students) TO STDOUT WITH CSV HEADER;

-- Export teachers
COPY (SELECT * FROM teachers) TO STDOUT WITH CSV HEADER;

-- Export sections
COPY (SELECT * FROM sections) TO STDOUT WITH CSV HEADER;

-- Export classes
COPY (SELECT * FROM classes) TO STDOUT WITH CSV HEADER;

-- Export madrasa_income
COPY (SELECT * FROM madrasa_income) TO STDOUT WITH CSV HEADER;

-- Export madrasa_expenditure
COPY (SELECT * FROM madrasa_expenditure) TO STDOUT WITH CSV HEADER;

-- Export masjid_income
COPY (SELECT * FROM masjid_income) TO STDOUT WITH CSV HEADER;

-- Export masjid_expenditure
COPY (SELECT * FROM masjid_expenditure) TO STDOUT WITH CSV HEADER;
```

## Step 2: Import Data to Neon

### Using Neon SQL Editor

After creating tables (using NEON_DATABASE_SETUP.sql), import data:

```sql
-- Import sections first (referenced by other tables)
COPY sections(id, name, institution, type, created_at, updated_at)
FROM '/path/to/sections.csv'
DELIMITER ','
CSV HEADER;

-- Import classes
COPY classes(id, name, status, created_at, updated_at)
FROM '/path/to/classes.csv'
DELIMITER ','
CSV HEADER;

-- Import students
COPY students(id, name, father_name, mobile_no, class, fee, status, admission_date, struck_off_date, graduation_date, image, created_at, updated_at)
FROM '/path/to/students.csv'
DELIMITER ','
CSV HEADER;

-- Import teachers
COPY teachers(id, name, mobile_no, starting_date, status, leaving_date, salary, created_at, updated_at)
FROM '/path/to/teachers.csv'
DELIMITER ','
CSV HEADER;

-- Import madrasa_income
COPY madrasa_income(id, description, rs, date, section_id, created_at, updated_at)
FROM '/path/to/madrasa_income.csv'
DELIMITER ','
CSV HEADER;

-- Import madrasa_expenditure
COPY madrasa_expenditure(id, description, rs, date, section_id, created_at, updated_at)
FROM '/path/to/madrasa_expenditure.csv'
DELIMITER ','
CSV HEADER;

-- Import masjid_income
COPY masjid_income(id, description, rs, date, section_id, created_at, updated_at)
FROM '/path/to/masjid_income.csv'
DELIMITER ','
CSV HEADER;

-- Import masjid_expenditure
COPY masjid_expenditure(id, description, rs, date, section_id, created_at, updated_at)
FROM '/path/to/masjid_expenditure.csv'
DELIMITER ','
CSV HEADER;

-- Reset sequences to avoid ID conflicts
SELECT setval('students_id_seq', (SELECT MAX(id) FROM students));
SELECT setval('teachers_id_seq', (SELECT MAX(id) FROM teachers));
SELECT setval('sections_id_seq', (SELECT MAX(id) FROM sections));
SELECT setval('classes_id_seq', (SELECT MAX(id) FROM classes));
SELECT setval('madrasa_income_id_seq', (SELECT MAX(id) FROM madrasa_income));
SELECT setval('madrasa_expenditure_id_seq', (SELECT MAX(id) FROM madrasa_expenditure));
SELECT setval('masjid_income_id_seq', (SELECT MAX(id) FROM masjid_income));
SELECT setval('masjid_expenditure_id_seq', (SELECT MAX(id) FROM masjid_expenditure));
```

### Using Neon Console UI (Easier)
1. Go to Neon Console → Tables
2. Select each table
3. Click "Import" button
4. Upload CSV file
5. Map columns
6. Import

## Step 3: Verify Data

After import, verify record counts:

```sql
SELECT 'students' as table_name, COUNT(*) as count FROM students
UNION ALL
SELECT 'teachers', COUNT(*) FROM teachers
UNION ALL
SELECT 'sections', COUNT(*) FROM sections
UNION ALL
SELECT 'classes', COUNT(*) FROM classes
UNION ALL
SELECT 'madrasa_income', COUNT(*) FROM madrasa_income
UNION ALL
SELECT 'madrasa_expenditure', COUNT(*) FROM madrasa_expenditure
UNION ALL
SELECT 'masjid_income', COUNT(*) FROM masjid_income
UNION ALL
SELECT 'masjid_expenditure', COUNT(*) FROM masjid_expenditure;
```

Compare these counts with your Supabase database to ensure all data migrated successfully.

## Next Steps

Once data is migrated, update your Flutter app to connect to Neon (see NEON_FLUTTER_UPDATE.md).
