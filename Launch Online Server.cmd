@echo off
cd /d "%~dp0"
title LittleGod 0.7 - Local Universe API
if not exist "tools\postgres\pgsql\bin\postgres.exe" pwsh -NoProfile -File "devtools\setup_postgres.ps1"
if errorlevel 1 exit /b 1
pwsh -NoProfile -File "devtools\start_online.ps1"
pause
