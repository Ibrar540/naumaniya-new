-- Add leaving_date column to teachers table if it doesn't exist
-- Run this in your Neon PostgreSQL database

-- Check if column exists and add it if not
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'teachers' 
        AND column_name = 'leaving_date'
    ) THEN
        ALTER TABLE teachers 
        ADD COLUMN leaving_date VARCHAR(50);
        
        RAISE NOTICE 'Column leaving_date added to teachers table';
    ELSE
        RAISE NOTICE 'Column leaving_date already exists in teachers table';
    END IF;
END $$;

-- Optional: Set default value for existing records
UPDATE teachers 
SET leaving_date = NULL 
WHERE leaving_date IS NULL OR leaving_date = '';

COMMENT ON COLUMN teachers.leaving_date IS 'Date when teacher left the institution';
