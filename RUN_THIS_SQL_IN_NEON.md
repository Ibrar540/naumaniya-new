# SQL Migration - Add Roll Number Column

## Instructions

1. Go to your Neon Console: https://console.neon.tech/
2. Select your project
3. Click on "SQL Editor" in the left sidebar
4. Copy and paste the SQL below
5. Click "Run" to execute

## SQL Script

```sql
-- Add roll_no column to students table
ALTER TABLE students ADD COLUMN IF NOT EXISTS roll_no INTEGER;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_students_roll_no ON students(roll_no);

-- Add comment
COMMENT ON COLUMN students.roll_no IS 'Permanent roll number assigned to student within their class';

-- Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'students' AND column_name = 'roll_no';
```

## Expected Output

You should see:
```
column_name | data_type | is_nullable
------------|-----------|------------
roll_no     | integer   | YES
```

## How Roll Numbers Work Now

### Assignment Logic:
1. **Oldest student** (lowest ID) → **Roll No 1**
2. **Second oldest** → **Roll No 2**
3. **Newest student** (highest ID) → **Highest Roll No**

### Display Order:
- **Top of table**: Highest roll number (newest student)
- **Bottom of table**: Roll No 1 (oldest student)

### Example:
If you have 3 students in "Class A":
- Student ID 5 (oldest) → Roll No 1 → Shows at BOTTOM
- Student ID 8 → Roll No 2 → Shows in MIDDLE
- Student ID 10 (newest) → Roll No 3 → Shows at TOP

When you add a 4th student with ID 12:
- Student ID 5 (oldest) → Roll No 1 → Shows at BOTTOM
- Student ID 8 → Roll No 2
- Student ID 10 → Roll No 3
- Student ID 12 (newest) → Roll No 4 → Shows at TOP

## Verification

After running the SQL:
1. Restart your Flutter app
2. Go to Classes Module
3. Click on a class
4. Click "View Data"
5. You should see students with roll numbers, highest at top

## Troubleshooting

If you get an error:
- Make sure you're connected to the correct database
- Check that the students table exists
- Try running each statement separately

If roll numbers don't appear:
- Check the console logs for any errors
- Make sure students have a class assigned
- Verify the class name matches exactly (case-sensitive)
