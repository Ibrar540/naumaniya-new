-- Add residency_status column to admissions table
-- Run this SQL in your Neon database console

ALTER TABLE admissions 
ADD COLUMN residency_status VARCHAR(20) DEFAULT 'Resident';

-- Update existing records to have default value
UPDATE admissions 
SET residency_status = 'Resident' 
WHERE residency_status IS NULL;

-- Add comment to column
COMMENT ON COLUMN admissions.residency_status IS 'Student residency status: Resident or Non_Resident';
