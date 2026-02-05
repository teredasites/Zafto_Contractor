@echo off
cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto_Electrical"
echo Working directory: %CD%
echo.
echo Cleaning project...
call C:\tools\flutter\bin\flutter.bat clean
echo.
echo Getting packages...
call C:\tools\flutter\bin\flutter.bat pub get
echo.
echo Running WITHOUT clean build...
set CHROME_EXECUTABLE=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe
call C:\tools\flutter\bin\flutter.bat run -d chrome --web-port=5000
pause
