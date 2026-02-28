# Budget Tables Structure Mismatch

## Current Situation

### Your Supabase Tables:
```sql
-- 4 separate tables
madrasa_income: id, description, rs, date
madrasa_expenditure: id, description, rs, date
masjid_income: id, description, rs, date
masjid_expenditure: id, description, rs, date
```

### App Expects:
```sql
-- 1 unified table
madrasa_budget: id, description, amount, date, type, section_id, institution
```

## The Problem

1. **Missing Columns**: Your tables don't have:
   - `section_id` - Required for organizing income/expenditure by sections
   - `institution` - Required to distinguish madrasa vs masjid
   - `type` - Required to distinguish income vs expenditure

2. **Different Column Names**:
   - Your tables use `rs` (rupees)
   - App expects `amount`

3. **Sections Feature**: The app's sections feature won't work without `section_id`

---

## Solution Options

### Option 1: Update Your Tables (Recommended)

Add the missing columns to your existing tables:

```sql
-- Add section_id to all tables
ALTER TABLE madrasa_income ADD COLUMN section_id BIGINT;
ALTER TABLE madrasa_expenditure ADD COLUMN section_id BIGINT;
ALTER TABLE masjid_income ADD COLUMN section_id BIGINT;
ALTER TABLE masjid_expenditure ADD COLUMN section_id BIGINT;

-- Rename rs to amount (optional, or we can update the app)
ALTER TABLE madrasa_income RENAME COLUMN rs TO amount;
ALTER TABLE madrasa_expenditure RENAME COLUMN rs TO amount;
ALTER TABLE masjid_income RENAME COLUMN rs TO amount;
ALTER TABLE masjid_expenditure RENAME COLUMN rs TO amount;
```

Then update the app code to use 4 separate tables instead of 1 unified table.

### Option 2: Create New Unified Table

Create a new table that matches what the app expects:

```sql
CREATE TABLE madrasa_budget (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC,
  date DATE,
  type TEXT, -- 'income' or 'expenditure'
  section_id BIGINT,
  institution TEXT -- 'madrasa' or 'masjid'
);
```

Then migrate your existing data to this new table.

### Option 3: Update App to Match Your Tables

Update the app code to:
- Use 4 separate tables
- Use `rs` instead of `amount`
- Remove sections feature (or make it optional)

---

## Recommendation

**I recommend Option 1** because:
1. Keeps your existing data
2. Adds sections feature (useful for organizing budget)
3. Minimal changes needed

---

## What Sections Feature Does

Sections allow you to organize income/expenditure into categories:

**Example Madrasa Income Sections:**
- Student Fees
- Donations
- Zakat
- Other Income

**Example Madrasa Expenditure Sections:**
- Teacher Salaries
- Utilities
- Maintenance
- Books & Supplies

Without sections, all income/expenditure entries are just in one big list.

---

## Next Steps

Please choose which option you prefer:

1. **Option 1**: Add columns to existing tables (I'll update the app code)
2. **Option 2**: Create new unified table (I'll provide migration script)
3. **Option 3**: Update app to work without sections (simpler but less features)

Let me know which option you'd like, and I'll implement it!
