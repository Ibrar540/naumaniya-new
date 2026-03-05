@echo off
echo.
echo ╔════════════════════════════════════════════╗
echo ║   VERCEL DEPLOYMENT SCRIPT                 ║
echo ║   AI Assistant Backend                     ║
echo ╚════════════════════════════════════════════╝
echo.

REM Check Node.js
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed!
    echo Please install from: https://nodejs.org/
    pause
    exit /b 1
)

echo [✓] Node.js found
node --version
npm --version
echo.

REM Check Vercel CLI
where vercel >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [STEP 1/5] Installing Vercel CLI...
    call npm install -g vercel
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install Vercel CLI
        pause
        exit /b 1
    )
)

echo [✓] Vercel CLI found
vercel --version
echo.

REM Login to Vercel
echo [STEP 2/5] Logging in to Vercel...
echo This will open your browser for authentication
echo.
call vercel login
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Login failed
    pause
    exit /b 1
)

echo [✓] Logged in successfully
echo.

REM Deploy
echo [STEP 3/5] Deploying to Vercel...
echo.
call vercel
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Deployment failed
    pause
    exit /b 1
)

echo.
echo [✓] Deployed successfully
echo.

REM Add environment variable
echo [STEP 4/5] Adding DATABASE_URL environment variable...
echo.
echo Please enter your Neon DATABASE_URL:
set /p db_url="DATABASE_URL: "

call vercel env add DATABASE_URL production
echo %db_url%

echo.
echo [✓] Environment variable added
echo.

REM Deploy to production
echo [STEP 5/5] Deploying to production...
echo.
call vercel --prod
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Production deployment failed
    pause
    exit /b 1
)

echo.
echo ╔════════════════════════════════════════════╗
echo ║   DEPLOYMENT COMPLETE! ✅                  ║
echo ╚════════════════════════════════════════════╝
echo.
echo Your backend is now live on Vercel!
echo.
echo Next steps:
echo 1. Copy your Vercel URL from above
echo 2. Update Flutter app (lib/services/ai_chat_service.dart)
echo 3. Change _backendUrl to your Vercel URL
echo 4. Test your app!
echo.
echo To view logs: vercel logs
echo To redeploy: vercel --prod
echo.
pause
