# Fix Teachers Table in Supabase

## Problem
The app is trying to insert a teacher with a `mobile` column, but your Supabase `teachers` table doesn't have this column.

Error: `Could not find the mobile column of 'teachers'`

---

## Solution

### Option 1: Add the missing column (Recommended)

Run this SQL in your Supabase SQL Editor:

```sql
-- Add mobile column if it doesn't exist
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS mobile TEXT;
```

### Option 2: Check if column has a different name

Your table might have the column with a different name. Run this to check:

```sql
-- Check current columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'teachers'
ORDER BY ordinal_position;
```

If you see a column like `phone`, `mobile_no`, or `mobile_number`, you can either:

**A) Rename it to `mobile`:**
```sql
ALTER TABLE teachers RENAME COLUMN phone TO mobile;
-- OR
ALTER TABLE teachers RENAME COLUMN mobile_no TO mobile;
```

**B) Or update the app code to use your column name** (see below)

---

## Expected Teachers Table Structure

Your `teachers` table should have these columns:

```sql
CREATE TABLE teachers (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  mobile TEXT,
  starting_date DATE,
  status TEXT DEFAULT 'Active',
  leaving_date TEXT,
  salary INTEGER
);
```

---

## If You Want to Keep Your Current Column Name

If your table has `phone` instead of `mobile`, update the code:

### Update `lib/services/supabase_service.dart`:

Find the `addTeacher` method (around line 170) and change:
```dart
// Change this:
'mobile': teacher.mobile,

// To this (if your column is named 'phone'):
'phone': teacher.mobile,
```

Also update the `updateTeacher` method similarly.

---

## Quick Fix Steps

1. **Go to Supabase Dashboard**
2. **Click on "SQL Editor"**
3. **Run this SQL:**
   ```sql
   ALTER TABLE teachers ADD COLUMN IF NOT EXISTS mobile TEXT;
   ```
4. **Try adding a teacher again in your app**

---

## Verify the Fix

After running the SQL:

1. Go to Supabase Dashboard
2. Click on "Table Editor"
3. Select "teachers" table
4. Check that you see a "mobile" column
5. Try adding a teacher in your app

---

**Status**: Run the SQL script above to fix the issue!
