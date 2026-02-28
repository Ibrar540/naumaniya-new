-- Check current teachers table structure
-- Run this first to see what columns exist:
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'teachers';

-- If the mobile column doesn't exist, add it:
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS mobile TEXT;

-- If you need to rename an existing column (e.g., if it's called 'phone' or 'mobile_no'):
-- ALTER TABLE teachers RENAME COLUMN phone TO mobile;
-- OR
-- ALTER TABLE teachers RENAME COLUMN mobile_no TO mobile;

-- Verify the final structure:
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'teachers'
ORDER BY ordinal_position;
