@echo off
echo Cleaning Flutter build cache...
flutter clean

echo.
echo Rebuilding Windows app...
flutter build windows --debug

echo.
echo Done! Now run: flutter run -d windows
pause
