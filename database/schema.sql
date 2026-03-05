-- Neon Database Setup Script
-- Run this in Neon SQL Editor to create all tables

-- 1. Students Table
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    roll_no INTEGER,
    name VARCHAR(255) NOT NULL,
    father_name VARCHAR(255),
    mobile_no BIGINT,
    class VARCHAR(100),
    fee NUMERIC(10, 2),
    status VARCHAR(50) DEFAULT 'active',
    admission_date DATE,
    struck_off_date DATE,
    graduation_date DATE,
    image TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Teachers Table
CREATE TABLE IF NOT EXISTS teachers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    mobile_no BIGINT,
    starting_date DATE,
    status VARCHAR(50) DEFAULT 'Active',
    leaving_date DATE,
    salary NUMERIC(10, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Sections Table
CREATE TABLE IF NOT EXISTS sections (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    institution VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Classes Table
CREATE TABLE IF NOT EXISTS classes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Madrasa Income Table
CREATE TABLE IF NOT EXISTS madrasa_income (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    rs NUMERIC(10, 2) NOT NULL,
    date DATE NOT NULL,
    section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Madrasa Expenditure Table
CREATE TABLE IF NOT EXISTS madrasa_expenditure (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    rs NUMERIC(10, 2) NOT NULL,
    date DATE NOT NULL,
    section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Masjid Income Table
CREATE TABLE IF NOT EXISTS masjid_income (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    rs NUMERIC(10, 2) NOT NULL,
    date DATE NOT NULL,
    section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Masjid Expenditure Table
CREATE TABLE IF NOT EXISTS masjid_expenditure (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    rs NUMERIC(10, 2) NOT NULL,
    date DATE NOT NULL,
    section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_students_roll_no ON students(roll_no);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(class);
CREATE INDEX IF NOT EXISTS idx_students_status ON students(status);
CREATE INDEX IF NOT EXISTS idx_students_admission_date ON students(admission_date);

CREATE INDEX IF NOT EXISTS idx_teachers_status ON teachers(status);
CREATE INDEX IF NOT EXISTS idx_teachers_starting_date ON teachers(starting_date);

CREATE INDEX IF NOT EXISTS idx_sections_institution_type ON sections(institution, type);

CREATE INDEX IF NOT EXISTS idx_madrasa_income_section ON madrasa_income(section_id);
CREATE INDEX IF NOT EXISTS idx_madrasa_income_date ON madrasa_income(date);

CREATE INDEX IF NOT EXISTS idx_madrasa_expenditure_section ON madrasa_expenditure(section_id);
CREATE INDEX IF NOT EXISTS idx_madrasa_expenditure_date ON madrasa_expenditure(date);

CREATE INDEX IF NOT EXISTS idx_masjid_income_section ON masjid_income(section_id);
CREATE INDEX IF NOT EXISTS idx_masjid_income_date ON masjid_income(date);

CREATE INDEX IF NOT EXISTS idx_masjid_expenditure_section ON masjid_expenditure(section_id);
CREATE INDEX IF NOT EXISTS idx_masjid_expenditure_date ON masjid_expenditure(date);

-- Enable Row Level Security (optional, for future use)
-- ALTER TABLE students ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE sections ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE students IS 'Student admissions and records';
COMMENT ON TABLE teachers IS 'Teacher information and employment records';
COMMENT ON TABLE sections IS 'Budget sections for madrasa and masjid';
COMMENT ON TABLE classes IS 'Class/grade information';
COMMENT ON TABLE madrasa_income IS 'Madrasa income records';
COMMENT ON TABLE madrasa_expenditure IS 'Madrasa expenditure records';
COMMENT ON TABLE masjid_income IS 'Masjid income records';
COMMENT ON TABLE masjid_expenditure IS 'Masjid expenditure records';
