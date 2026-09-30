@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Dashboard.ps1"
if errorlevel 1 (
 echo.
 echo Der lokale Dashboard-Server konnte nicht gestartet werden.
 pause
)
