@echo off
title ZAFTO Trades
color 0A

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║                                                           ║
echo  ║     ███████╗ █████╗ ███████╗████████╗ ██████╗            ║
echo  ║     ╚══███╔╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗           ║
echo  ║       ███╔╝ ███████║█████╗     ██║   ██║   ██║           ║
echo  ║      ███╔╝  ██╔══██║██╔══╝     ██║   ██║   ██║           ║
echo  ║     ███████╗██║  ██║██║        ██║   ╚██████╔╝           ║
echo  ║     ╚══════╝╚═╝  ╚═╝╚═╝        ╚═╝    ╚═════╝            ║
echo  ║                                                           ║
echo  ║                      TRADES                               ║
echo  ║                                                           ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.

:: ========================================
:: CONFIGURATION
:: ========================================
set FLUTTER=C:\tools\flutter\bin\flutter.bat
set CHROME_EXECUTABLE=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe
set PROJECT=C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto\apps\Trades
set PORT=5000

:: ========================================
:: VALIDATION
:: ========================================
if not exist "%FLUTTER%" (
    color 0C
    echo  [ERROR] Flutter not found at: %FLUTTER%
    echo.
    goto end
)

if not exist "%CHROME_EXECUTABLE%" (
    color 0E
    echo  [WARNING] Brave Browser not found - Chrome will be used
    set CHROME_EXECUTABLE=
)

if not exist "%PROJECT%\pubspec.yaml" (
    color 0C
    echo  [ERROR] Project not found at: %PROJECT%
    echo.
    goto end
)

:: ========================================
:: NAVIGATE TO PROJECT
:: ========================================
cd /d "%PROJECT%"
echo  [OK] Project: %CD%
echo  [OK] Flutter: %FLUTTER%
echo  [OK] Browser: Brave on port %PORT%
echo.

:: ========================================
:: GET DEPENDENCIES
:: ========================================
echo  [1/2] Getting dependencies...
call "%FLUTTER%" pub get
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo  [ERROR] pub get failed!
    goto end
)
echo.

:: ========================================
:: LAUNCH APP
:: ========================================
echo  ════════════════════════════════════════════════════════════
echo   LAUNCHING ZAFTO TRADES
echo   Port: %PORT%  │  r = reload  │  R = restart  │  q = quit
echo  ════════════════════════════════════════════════════════════
echo.

call "%FLUTTER%" run -d chrome --web-port=%PORT%

:end
echo.
echo  Press any key to close...
pause >nul
