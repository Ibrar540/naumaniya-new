# Neon Database Migration - Complete Setup Guide

## ✅ What's Been Done

1. **Database Schema Created** (`NEON_DATABASE_SETUP.sql`)
   - All 8 tables defined (students, teachers, sections, classes, income/expenditure tables)
   - Indexes added for performance
   - Foreign key relationships configured

2. **Flutter App Updated**
   - Added `postgres: ^3.0.0` package to pubspec.yaml
   - Created `NeonDatabaseService` with all database operations
   - Created `DatabaseService` wrapper for easy switching
   - Updated `main.dart` to initialize Neon connection

3. **Migration Guides Created**
   - `NEON_DATA_MIGRATION.md` - How to export/import data
   - `NEON_MIGRATION_GUIDE.md` - Connection details and overview
   - `NEON_FLUTTER_MIGRATION.md` - Migration strategy options

## 🚀 Next Steps

### Step 1: Set Up Neon Database (5 minutes)

1. Go to [Neon Console](https://console.neon.tech)
2. Open SQL Editor
3. Copy and paste the entire content from `NEON_DATABASE_SETUP.sql`
4. Click "Run" to create all tables

### Step 2: Export Data from Supabase (10 minutes)

#### Option A: Using Supabase Dashboard (Easiest)
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Table Editor
4. For each table, click "..." → Export as CSV
5. Download CSV files for all 8 tables

#### Option B: Using SQL
Run these queries in Supabase SQL Editor:

```sql
-- Export students
COPY (SELECT * FROM students) TO STDOUT WITH CSV HEADER;

-- Export teachers  
COPY (SELECT * FROM teachers) TO STDOUT WITH CSV HEADER;

-- Export sections
COPY (SELECT * FROM sections) TO STDOUT WITH CSV HEADER;

-- Export classes
COPY (SELECT * FROM classes) TO STDOUT WITH CSV HEADER;

-- Export madrasa_income
COPY (SELECT * FROM madrasa_income) TO STDOUT WITH CSV HEADER;

-- Export madrasa_expenditure
COPY (SELECT * FROM madrasa_expenditure) TO STDOUT WITH CSV HEADER;

-- Export masjid_income
COPY (SELECT * FROM masjid_income) TO STDOUT WITH CSV HEADER;

-- Export masjid_expenditure
COPY (SELECT * FROM masjid_expenditure) TO STDOUT WITH CSV HEADER;
```

### Step 3: Import Data to Neon (10 minutes)

1. Go to Neon Console → Tables
2. For each table:
   - Click on the table name
   - Click "Import" button
   - Upload the CSV file
   - Map columns (should auto-map)
   - Click "Import"

3. After importing all data, run this in SQL Editor to fix sequences:

```sql
SELECT setval('students_id_seq', (SELECT MAX(id) FROM students));
SELECT setval('teachers_id_seq', (SELECT MAX(id) FROM teachers));
SELECT setval('sections_id_seq', (SELECT MAX(id) FROM sections));
SELECT setval('classes_id_seq', (SELECT MAX(id) FROM classes));
SELECT setval('madrasa_income_id_seq', (SELECT MAX(id) FROM madrasa_income));
SELECT setval('madrasa_expenditure_id_seq', (SELECT MAX(id) FROM madrasa_expenditure));
SELECT setval('masjid_income_id_seq', (SELECT MAX(id) FROM masjid_income));
SELECT setval('masjid_expenditure_id_seq', (SELECT MAX(id) FROM masjid_expenditure));
```

### Step 4: Update Flutter Dependencies (2 minutes)

Run in your project directory:

```bash
flutter pub get
```

### Step 5: Update Provider Files (Important!)

You need to update your providers to use the new `DatabaseService` instead of `SupabaseService`.

#### Files to Update:

1. **lib/providers/teacher_provider.dart**
   - Replace `SupabaseService()` with `DatabaseService`
   - Remove stream-based methods (Neon doesn't support real-time)
   - Use polling or manual refresh instead

2. **lib/providers/budget_provider.dart**
   - Replace `SupabaseService()` with `DatabaseService`
   - Remove stream-based methods
   - Use polling or manual refresh instead

3. **All Screen Files** that use `SupabaseService`:
   - Search for `SupabaseService()` in your project
   - Replace with `DatabaseService`

### Step 6: Handle Real-Time Updates

Since Neon doesn't have real-time subscriptions like Supabase, you have two options:

#### Option A: Manual Refresh (Simplest)
Add a refresh button to screens that need updated data.

#### Option B: Polling (Automatic)
Use a timer to fetch data periodically:

```dart
Timer.periodic(Duration(seconds: 30), (timer) {
  // Refresh data
  loadData();
});
```

### Step 7: Test the App

1. Run the app:
```bash
flutter run
```

2. Test each module:
   - ✅ Students (add, edit, delete, search)
   - ✅ Teachers (add, edit, delete)
   - ✅ Classes (add, edit, delete)
   - ✅ Budget (income/expenditure for madrasa and masjid)
   - ✅ Sections

3. Check console for connection messages:
   - Should see: "✅ Neon database initialized successfully"

## 📝 Important Notes

### Connection Limitations

The `postgres` package works best for:
- ✅ Desktop apps (Windows, macOS, Linux)
- ✅ Web apps (with CORS configured)
- ⚠️ Mobile apps (may have connection issues)

For mobile apps, consider creating a backend API (see NEON_FLUTTER_MIGRATION.md).

### Security Note

The database credentials are currently hardcoded in `neon_database_service.dart`. For production:

1. Move credentials to environment variables
2. Use flutter_dotenv package
3. Create `.env` file:
```
NEON_HOST=ep-sparkling-sun-a1x8o3l5-pooler.ap-southeast-1.aws.neon.tech
NEON_DATABASE=neondb
NEON_USER=neondb_owner
NEON_PASSWORD=npg_eId5vglW0kKO
```

### Performance Tips

1. **Connection Pooling**: The service reuses a single connection
2. **Indexes**: Already created in the SQL script
3. **Batch Operations**: For bulk inserts, use transactions

## 🔄 Rollback Plan

If you need to go back to Supabase:

1. In `lib/services/database_service.dart`, change:
```dart
static final _neonService = NeonDatabaseService.instance;
```
to:
```dart
static final _supabaseService = SupabaseService();
```

2. Update all method calls to use `_supabaseService`

3. In `main.dart`, restore Supabase initialization

## 📊 Verification Checklist

After migration, verify:

- [ ] All tables created in Neon
- [ ] All data imported successfully
- [ ] Record counts match between Supabase and Neon
- [ ] App connects to Neon successfully
- [ ] Can add new records
- [ ] Can update existing records
- [ ] Can delete records
- [ ] Search functionality works
- [ ] All screens load data correctly

## 🆘 Troubleshooting

### Connection Failed
- Check Neon database is not paused (free tier pauses after inactivity)
- Verify credentials in `neon_database_service.dart`
- Check internet connection

### Data Not Showing
- Verify data was imported correctly in Neon Console
- Check console logs for errors
- Ensure sequences were reset after import

### App Crashes on Mobile
- The postgres package may not work well on mobile
- Consider creating a backend API (see NEON_FLUTTER_MIGRATION.md)

## 📞 Need Help?

If you encounter issues:
1. Check console logs for error messages
2. Verify Neon database is active (not paused)
3. Test connection in Neon SQL Editor first
4. Review the error messages carefully

## 🎉 Success!

Once everything is working:
- Your app is now using Neon PostgreSQL
- No more database pausing after a week
- Same functionality as before
- Better for free tier usage

---

**Migration Status**: Ready to execute
**Estimated Time**: 30-45 minutes
**Difficulty**: Medium

Good luck with your migration! 🚀
