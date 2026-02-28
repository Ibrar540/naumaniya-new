# Neon Database Migration Guide

## Your Neon Connection Details

- **Host**: `ep-sparkling-sun-a1x8o3l5-pooler.ap-southeast-1.aws.neon.tech`
- **Database**: `neondb`
- **User**: `neondb_owner`
- **Password**: `npg_eId5vglW0kKO`
- **Port**: `5432`
- **Connection String**: 
  ```
  postgresql://neondb_owner:npg_eId5vglW0kKO@ep-sparkling-sun-a1x8o3l5-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
  ```

## Migration Steps

### Step 1: Create Tables in Neon ✅

I'll create SQL scripts for all your tables:
1. students
2. teachers
3. sections
4. classes
5. madrasa_income
6. madrasa_expenditure
7. masjid_income
8. masjid_expenditure

### Step 2: Export Data from Supabase

You need to export data from your Supabase database. Go to:
1. Supabase Dashboard → Your Project
2. Table Editor → Select each table
3. Click "..." menu → Export as CSV
4. Download CSV files for all tables

### Step 3: Import Data to Neon

Once you have the CSV files, you can import them to Neon using:
1. Neon Console → SQL Editor
2. Use COPY command or import CSV through the UI

### Step 4: Update Flutter App

I'll update your app to use direct PostgreSQL connection with Neon instead of Supabase REST API.

## Important Note

Since Neon doesn't provide a REST API like Supabase, we need to:
- Replace `supabase_flutter` with `postgres` package for direct PostgreSQL connection
- Rewrite the database service to use SQL queries instead of REST API calls
- This is a significant change but will work better with Neon

## Alternative Approach (Easier)

Keep using `supabase_flutter` but configure it to connect to Neon's PostgreSQL endpoint. This might work with some limitations.

Which approach do you prefer?
1. **Full migration** to `postgres` package (more work, better for Neon)
2. **Try Supabase client** with Neon (easier, might have limitations)

Let me know and I'll proceed!
