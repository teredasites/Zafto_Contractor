@echo off
set FLUTTER=C:\tools\flutter\bin\flutter.bat
set CHROME_EXECUTABLE=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe

cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto_Electrical"
echo Current directory: %CD%
echo.

echo Running flutter build web --debug...
echo.
call %FLUTTER% build web --debug 2>&1 > debug_output.txt
type debug_output.txt
echo.
echo Build complete. Check debug_output.txt for full log.
pause
