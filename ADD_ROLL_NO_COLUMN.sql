-- Add roll_no column to students table
-- This column stores the permanent roll number for each student in their class

ALTER TABLE students ADD COLUMN IF NOT EXISTS roll_no INTEGER;

-- Create index for better performance when querying by roll_no
CREATE INDEX IF NOT EXISTS idx_students_roll_no ON students(roll_no);

-- Add comment
COMMENT ON COLUMN students.roll_no IS 'Permanent roll number assigned to student within their class';
