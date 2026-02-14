@echo off
title ZAFTO App Launcher
color 0B

echo.
echo  ======================================================
echo   ZAFTO - Launch Center
echo   Trade Contractor Business Platform
echo  ======================================================
echo.
echo  FLUTTER MOBILE APP:
echo    [1] Android Emulator (Phone)
echo    [2] Windows Desktop
echo    [3] Chrome / Edge (Web)
echo    [4] Build Android APK (debug)
echo    [5] Build Android APK (release)
echo.
echo  WEB PORTALS (opens in browser):
echo    [6] CRM Portal        - zafto.cloud
echo    [7] Team Portal        - team.zafto.cloud
echo    [8] Client Portal      - client.zafto.cloud
echo    [9] Ops Portal         - ops.zafto.cloud
echo.
echo  DEV SERVERS (localhost):
echo    [A] CRM Dev Server     - localhost:3000
echo    [B] Team Dev Server    - localhost:3001
echo    [C] Client Dev Server  - localhost:3002
echo    [D] Ops Dev Server     - localhost:3003
echo.
echo  TOOLS:
echo    [F] Flutter Doctor
echo    [G] Dart Analyze (check for errors)
echo    [H] Build ALL portals (verify)
echo    [Q] Quit
echo.

set /p choice="  Select option: "

if "%choice%"=="1" goto android_emulator
if "%choice%"=="2" goto windows_desktop
if "%choice%"=="3" goto chrome_web
if "%choice%"=="4" goto build_apk_debug
if "%choice%"=="5" goto build_apk_release
if "%choice%"=="6" goto crm_live
if "%choice%"=="7" goto team_live
if "%choice%"=="8" goto client_live
if "%choice%"=="9" goto ops_live
if /i "%choice%"=="A" goto crm_dev
if /i "%choice%"=="B" goto team_dev
if /i "%choice%"=="C" goto client_dev
if /i "%choice%"=="D" goto ops_dev
if /i "%choice%"=="F" goto flutter_doctor
if /i "%choice%"=="G" goto dart_analyze
if /i "%choice%"=="H" goto build_all
if /i "%choice%"=="Q" goto end

echo Invalid choice. Try again.
pause
goto end

:android_emulator
echo.
echo  Starting Android Emulator + Flutter app...
echo  (This may take 1-2 minutes on first launch)
echo.
start "" C:\tools\flutter\bin\flutter.bat emulators --launch Medium_Phone_API_36.1
timeout /t 15 /nobreak >nul
echo  Emulator booting... waiting 15s then launching app...
C:\tools\flutter\bin\flutter.bat run -d emulator
goto end

:windows_desktop
echo.
echo  Launching Zafto on Windows Desktop...
echo.
C:\tools\flutter\bin\flutter.bat run -d windows
goto end

:chrome_web
echo.
echo  Launching Zafto in Web Browser...
echo.
C:\tools\flutter\bin\flutter.bat run -d edge --web-port 5000
goto end

:build_apk_debug
echo.
echo  Building Android Debug APK...
echo.
C:\tools\flutter\bin\flutter.bat build apk --debug
echo.
echo  APK location: build\app\outputs\flutter-apk\app-debug.apk
echo  Transfer this file to your phone to install.
pause
goto end

:build_apk_release
echo.
echo  Building Android Release APK...
echo.
C:\tools\flutter\bin\flutter.bat build apk --release
echo.
echo  APK location: build\app\outputs\flutter-apk\app-release.apk
echo  Transfer this file to your phone to install.
pause
goto end

:crm_live
start "" "https://zafto.cloud"
goto end

:team_live
start "" "https://team.zafto.cloud"
goto end

:client_live
start "" "https://client.zafto.cloud"
goto end

:ops_live
start "" "https://ops.zafto.cloud"
goto end

:crm_dev
echo.
echo  Starting CRM dev server on localhost:3000...
echo.
cd web-portal
start "Zafto CRM Dev" cmd /c "npm run dev"
timeout /t 3 /nobreak >nul
start "" "http://localhost:3000"
cd ..
goto end

:team_dev
echo.
echo  Starting Team Portal dev server on localhost:3001...
echo.
cd team-portal
start "Zafto Team Dev" cmd /c "npm run dev -- -p 3001"
timeout /t 3 /nobreak >nul
start "" "http://localhost:3001"
cd ..
goto end

:client_dev
echo.
echo  Starting Client Portal dev server on localhost:3002...
echo.
cd client-portal
start "Zafto Client Dev" cmd /c "npm run dev -- -p 3002"
timeout /t 3 /nobreak >nul
start "" "http://localhost:3002"
cd ..
goto end

:ops_dev
echo.
echo  Starting Ops Portal dev server on localhost:3003...
echo.
cd ops-portal
start "Zafto Ops Dev" cmd /c "npm run dev -- -p 3003"
timeout /t 3 /nobreak >nul
start "" "http://localhost:3003"
cd ..
goto end

:flutter_doctor
echo.
C:\tools\flutter\bin\flutter.bat doctor -v
pause
goto end

:dart_analyze
echo.
echo  Running Dart Analyzer...
echo.
C:\tools\flutter\bin\flutter.bat analyze
pause
goto end

:build_all
echo.
echo  Building ALL portals...
echo.
echo  [1/4] Web CRM...
cd web-portal && call npm run build 2>&1 && echo   CRM: PASS || echo   CRM: FAIL
cd ..
echo  [2/4] Team Portal...
cd team-portal && call npm run build 2>&1 && echo   Team: PASS || echo   Team: FAIL
cd ..
echo  [3/4] Client Portal...
cd client-portal && call npm run build 2>&1 && echo   Client: PASS || echo   Client: FAIL
cd ..
echo  [4/4] Ops Portal...
cd ops-portal && call npm run build 2>&1 && echo   Ops: PASS || echo   Ops: FAIL
cd ..
echo.
echo  All builds complete.
pause
goto end

:end
echo.
echo  Done!
