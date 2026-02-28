# Complete Budget Tables Structure

## All 5 Tables

### 1. madrasa_income
```sql
Columns:
- id (BIGINT, PRIMARY KEY, AUTO INCREMENT)
- description (TEXT, NOT NULL)
- rs (NUMERIC, NULL)
- date (DATE, NULL)
- section_id (BIGINT, NULL) ← NEW COLUMN
```

### 2. madrasa_expenditure
```sql
Columns:
- id (BIGINT, PRIMARY KEY, AUTO INCREMENT)
- description (TEXT, NOT NULL)
- rs (NUMERIC, NULL)
- date (DATE, NULL)
- section_id (BIGINT, NULL) ← NEW COLUMN
```

### 3. masjid_income
```sql
Columns:
- id (BIGINT, PRIMARY KEY, AUTO INCREMENT)
- description (TEXT, NOT NULL)
- rs (NUMERIC, NULL)
- date (DATE, NULL)
- section_id (BIGINT, NULL) ← NEW COLUMN
```

### 4. masjid_expenditure
```sql
Columns:
- id (BIGINT, PRIMARY KEY, AUTO INCREMENT)
- description (TEXT, NOT NULL)
- rs (NUMERIC, NULL)
- date (DATE, NULL)
- section_id (BIGINT, NULL) ← NEW COLUMN
```

### 5. sections (NEW TABLE)
```sql
Columns:
- id (BIGSERIAL, PRIMARY KEY)
- name (TEXT, NOT NULL)
- institution (TEXT, NOT NULL) -- 'madrasa' or 'masjid'
- type (TEXT, NOT NULL) -- 'income' or 'expenditure'
```

## What the SQL Script Does

1. **Creates all 5 tables** (if they don't exist)
2. **Adds section_id column** to existing tables (if missing)
3. **Creates indexes** for better performance
4. **Adds sample sections** (optional - for testing)
5. **Verifies everything** worked correctly

## How to Run

1. Go to your Supabase Dashboard
2. Click "SQL Editor"
3. Copy the entire content of `COMPLETE_BUDGET_TABLES.sql`
4. Paste and click "Run"
5. Check the output - should see "All budget tables created/updated successfully!"

## After Running

Your tables will have this structure:

**Before:**
```
madrasa_income: id, description, rs, date
madrasa_expenditure: id, description, rs, date
masjid_income: id, description, rs, date
masjid_expenditure: id, description, rs, date
```

**After:**
```
madrasa_income: id, description, rs, date, section_id ✅
madrasa_expenditure: id, description, rs, date, section_id ✅
masjid_income: id, description, rs, date, section_id ✅
masjid_expenditure: id, description, rs, date, section_id ✅
sections: id, name, institution, type ✅ (NEW)
```

## Sample Sections Created

The script will create these sample sections:

**Madrasa Income:**
- Student Fees
- Donations
- Zakat

**Madrasa Expenditure:**
- Teacher Salaries
- Utilities
- Maintenance

**Masjid Income:**
- Donations
- Zakat

**Masjid Expenditure:**
- Imam Salary
- Utilities

## Testing

After running the script, test in your app:

1. Go to Madrasa Budget
2. Click "Income" → "Create Section"
3. You should see the sample sections
4. Try adding an income entry
5. It should work! ✅

## Notes

- The script is **safe to run multiple times** (uses IF NOT EXISTS)
- Your existing data will **not be deleted**
- The `section_id` column will be **NULL** for existing entries (that's okay)
- You can assign sections to existing entries later

---

**Status:** Ready to run! 🚀
