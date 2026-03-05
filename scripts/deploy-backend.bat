@echo off
echo ========================================
echo   Backend Deployment to Vercel
echo ========================================
echo.

cd backend

echo Step 1: Installing Vercel CLI (if not installed)...
call npm install -g vercel
echo.

echo Step 2: Deploying to Vercel...
call vercel --prod
echo.

echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Your backend is now live at:
echo https://naumaniya-new.vercel.app
echo.
pause
