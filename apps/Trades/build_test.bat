@echo off
title ZAFTO - Web Build Test
color 0A

set FLUTTER=C:\tools\flutter\bin\flutter.bat
set CHROME_EXECUTABLE=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe

pushd "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto_Electrical"
echo Current: %CD%
echo.

echo === Cleaning ===
call %FLUTTER% clean
echo.

echo === Pub get ===
call %FLUTTER% pub get
echo.

echo === Building web (debug) ===
call %FLUTTER% build web --debug 2>&1
echo.

echo === Build complete ===
pause
