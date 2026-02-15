@echo off
title ZAFTO Mobile UI Preview
color 0A

echo ============================================================
echo   ZAFTO Mobile UI Preview
echo   Launches Flutter app in Chrome (mobile viewport)
echo ============================================================
echo.

:: Check Flutter
if not exist "C:\tools\flutter\bin\flutter.bat" (
    echo [ERROR] Flutter not found at C:\tools\flutter\bin\flutter.bat
    echo Install Flutter or update the path in this script.
    pause
    exit /b 1
)

set FLUTTER=C:\tools\flutter\bin\flutter.bat

echo [1/3] Checking Flutter devices...
%FLUTTER% devices 2>nul

echo.
echo ============================================================
echo   Choose preview mode:
echo ============================================================
echo.
echo   1) Chrome (web) - Fastest, no emulator needed
echo   2) Windows Desktop - Native desktop window
echo   3) Android Emulator - Requires AVD setup
echo   4) Run dart analyze first
echo   5) Exit
echo.

set /p choice="Enter choice (1-5): "

if "%choice%"=="1" goto chrome
if "%choice%"=="2" goto windows
if "%choice%"=="3" goto android
if "%choice%"=="4" goto analyze
if "%choice%"=="5" exit /b 0

:chrome
echo.
echo [2/3] Building Flutter web...
echo [INFO] App will open in Chrome with mobile viewport (390x844 - iPhone 14 Pro)
echo [INFO] Press Ctrl+C in this window to stop the app
echo.
cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto\apps\Trades"
%FLUTTER% run -d chrome --web-browser-flag="--window-size=390,844" --web-renderer html
goto end

:windows
echo.
echo [2/3] Building Flutter Windows app...
echo [INFO] Press Ctrl+C in this window to stop the app
echo.
cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto\apps\Trades"
%FLUTTER% run -d windows
goto end

:android
echo.
echo [2/3] Launching Android emulator...
echo [INFO] Make sure an AVD is configured in Android Studio
echo.
cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto\apps\Trades"
%FLUTTER% emulators --launch Pixel_7_API_34 2>nul
timeout /t 10 /nobreak >nul
echo [3/3] Running app on emulator...
%FLUTTER% run -d emulator
goto end

:analyze
echo.
echo Running dart analyze...
echo.
cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto\apps\Trades"
%FLUTTER% analyze
echo.
echo Analysis complete. Press any key to return to menu...
pause >nul
goto chrome

:end
echo.
echo ============================================================
echo   ZAFTO Mobile Preview closed.
echo ============================================================
pause
