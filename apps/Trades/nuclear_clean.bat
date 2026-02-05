@echo off
echo ============================================
echo    NUCLEAR CLEAN - Full Reset
echo ============================================

cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto_Electrical"

echo Killing any running Dart processes...
taskkill /f /im dart.exe 2>nul
taskkill /f /im flutter.exe 2>nul
timeout /t 2 /nobreak >nul

echo Deleting build folders...
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q windows\flutter\ephemeral 2>nul
del /f /q pubspec.lock 2>nul

echo Clearing Flutter cache...
call C:\tools\flutter\bin\flutter.bat clean

echo Getting fresh packages...
call C:\tools\flutter\bin\flutter.bat pub get

echo.
echo ============================================
echo    Clean complete! Now run zaftorun.bat
echo ============================================
pause
