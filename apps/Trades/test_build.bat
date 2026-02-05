@echo off
title ZAFTO - Debug Build Test
color 0A

set FLUTTER=C:\tools\flutter\bin\flutter.bat
set CHROME_EXECUTABLE=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe

cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto_Electrical"
echo Current: %CD%
echo.

echo === STEP 1: Delete .dart_tool completely ===
rd /s /q ".dart_tool" 2>nul
echo Done.
echo.

echo === STEP 2: Delete build folder ===
rd /s /q "build" 2>nul
echo Done.
echo.

echo === STEP 3: Fresh pub get ===
call %FLUTTER% pub get
echo.

echo === STEP 4: Try run with --no-tree-shake-icons ===
call %FLUTTER% run -d chrome --web-port=5000 --no-tree-shake-icons

pause
