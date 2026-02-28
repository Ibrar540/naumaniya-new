@echo off
echo Creating tables in Neon database...
echo.

set PGPASSWORD=npg_eId5vglW0kKO

psql "postgresql://neondb_owner@ep-sparkling-sun-a1x8o3l5-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require" -f NEON_DATABASE_SETUP.sql

echo.
echo Done! Check above for any errors.
pause
