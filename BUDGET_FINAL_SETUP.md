# Budget Module - Final Setup Guide

## Step 1: Run SQL Script ✅

**Run this in your Supabase SQL Editor:**

See file: `ADD_BUDGET_COLUMNS.sql`

This will:
1. Add `section_id` column to all 4 tables
2. Create `sections` table
3. Create indexes for performance

## Step 2: App Updates Needed

The app currently uses a single `madrasa_budget` table, but you have 4 separate tables. I need to update the SupabaseService to use the correct table based on institution and type.

### Current Code:
```dart
// Uses single table
_client.from('madrasa_budget')
  .insert(data)
  .eq('type', 'income')
  .eq('institution', 'madrasa');
```

### New Code Needed:
```dart
// Use specific table
String tableName = _getTableName(institution, type);
// Returns: 'madrasa_income', 'madrasa_expenditure', 'masjid_income', or 'masjid_expenditure'
_client.from(tableName).insert(data);
```

## Step 3: Field Name Compatibility

Your tables use `rs` but the app uses `amount`. I've updated the models to support both:

```dart
// Income/Expenditure models now read from both:
final amountField = map['amount'] ?? map['rs'];
```

**Options:**
1. **Keep `rs`** - App will work (models support both)
2. **Rename to `amount`** - Uncomment lines in SQL script

## Step 4: Testing After SQL

After running the SQL:

1. **Verify columns exist:**
   ```sql
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'madrasa_income';
   ```
   Should show: id, description, rs, date, section_id

2. **Create a test section:**
   ```sql
   INSERT INTO sections (name, institution, type) 
   VALUES ('Student Fees', 'madrasa', 'income');
   ```

3. **Test the app:**
   - Go to Madrasa Budget
   - Try creating a section
   - Try adding income/expenditure

## Current Status

✅ Models updated to support both `rs` and `amount`
✅ SQL script ready
⏳ SupabaseService needs update (major work)

## Next Steps

After you run the SQL script, I need to update the SupabaseService to use your 4 tables instead of 1. This requires updating ~20 methods.

**Should I proceed with updating SupabaseService?**

This will take significant time and changes. Let me know when you've run the SQL and I'll continue!
