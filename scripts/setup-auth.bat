@echo off
echo ========================================
echo   Authentication System Setup
echo ========================================
echo.

echo Step 1: Installing backend dependencies...
cd backend
call npm install bcrypt jsonwebtoken
echo.

echo Step 2: Running database schema...
echo Please run this SQL file in your Neon database:
echo   database/auth_schema.sql
echo.
echo You can do this via:
echo   1. Neon web console (SQL Editor)
echo   2. psql command line
echo   3. Any PostgreSQL client
echo.

echo Step 3: Set environment variables...
echo Create backend/.env file with:
echo   JWT_SECRET=your-super-secret-key
echo   DATABASE_URL=your-neon-connection-string
echo.

echo Step 4: Deploy backend...
echo Run: git add . && git commit -m "Add auth" && git push
echo.

echo ========================================
echo   Setup Instructions Complete!
echo ========================================
echo.
echo IMPORTANT: Change default admin password!
echo   Default: admin / admin123
echo.
pause
