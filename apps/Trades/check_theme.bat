@echo off
cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto_Electrical"
echo Working directory: %CD%
call C:\tools\flutter\bin\flutter.bat pub get
call C:\tools\flutter\bin\flutter.bat analyze lib/theme lib/main.dart --no-fatal-infos
pause
