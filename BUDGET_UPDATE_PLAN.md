# Budget Module Update Plan

## Summary
Updating the app to work with your 4 separate budget tables without sections feature.

## Changes Made So Far ✅

### 1. Models Updated:
- ✅ `lib/models/income.dart` - Changed `amount` to `rs`, removed sections
- ✅ `lib/models/expenditure.dart` - Changed `amount` to `rs`, removed sections

## Remaining Changes Needed

### 2. SupabaseService (lib/services/supabase_service.dart)
Need to update all budget methods to use 4 tables:
- `madrasa_income` instead of `madrasa_budget WHERE type='income' AND institution='madrasa'`
- `madrasa_expenditure` instead of `madrasa_budget WHERE type='expenditure' AND institution='madrasa'`
- `masjid_income` instead of `madrasa_budget WHERE type='income' AND institution='masjid'`
- `masjid_expenditure` instead of `madrasa_budget WHERE type='expenditure' AND institution='masjid'`

Methods to update:
- `getIncomesStream()` - Split into 2 methods (madrasa/masjid)
- `getAllIncomes()` - Split into 2 methods
- `getIncomeBySection()` - Remove (no sections)
- `addIncome()` - Use correct table based on institution
- `updateIncome()` - Use correct table based on institution
- `deleteIncome()` - Use correct table based on institution
- Same for all Expenditure methods
- Remove all Section methods

### 3. BudgetProvider (lib/providers/budget_provider.dart)
- Remove section-related methods
- Update to work without sections
- Update method calls to match new SupabaseService

### 4. Budget Screens
Need to simplify all budget screens to work without sections:

**Files to update:**
- `lib/screens/budget_management_screen.dart` - Remove section selection
- `lib/screens/madrasa_budget_screen.dart` - Direct income/expenditure entry
- `lib/screens/masjid_budget_screen.dart` - Direct income/expenditure entry
- `lib/screens/section_action_screen.dart` - Remove or simplify
- `lib/screens/section_options_screen.dart` - Remove or simplify
- `lib/screens/section_data_screen.dart` - Remove or simplify

### 5. UI Changes
**Before (with sections):**
```
Madrasa Budget
  → Income Sections
    → Student Fees (section)
      → Add Entry
      → View Entries
    → Donations (section)
      → Add Entry
      → View Entries
  → Expenditure Sections
    → Teacher Salaries (section)
      → Add Entry
      → View Entries
```

**After (without sections):**
```
Madrasa Budget
  → Income
    → Add Entry
    → View All Entries
  → Expenditure
    → Add Entry
    → View All Entries
```

## Recommendation

This is a **major refactoring** that will affect many files. I recommend:

### Option A: Keep Current System (Easier)
Add the missing columns to your tables:
```sql
ALTER TABLE madrasa_income ADD COLUMN section_id BIGINT;
ALTER TABLE madrasa_expenditure ADD COLUMN section_id BIGINT;
ALTER TABLE masjid_income ADD COLUMN section_id BIGINT;
ALTER TABLE masjid_expenditure ADD COLUMN section_id BIGINT;
```

Then just update field names (`rs` → `amount`) and table names in the app.

### Option B: Complete Refactor (Current Path)
Remove sections feature entirely and simplify the budget module.

**Pros:**
- Simpler UI
- Matches your table structure
- No sections to manage

**Cons:**
- All income/expenditure in one big list
- Harder to organize and categorize
- Major code changes required
- Risk of breaking existing functionality

## My Recommendation

**I strongly recommend Option A** because:
1. Sections are useful for organizing budget data
2. Less code changes = less risk
3. Better user experience
4. Your tables already exist, just need one column added

Would you like me to:
1. **Continue with Option B** (remove sections, major refactor)
2. **Switch to Option A** (add columns, minor updates)

Please let me know which approach you prefer!
