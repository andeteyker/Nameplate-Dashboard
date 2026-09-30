@echo off
setlocal
cd /d "%~dp0"
echo Nameplate Dashboard Updater
rem Laufende Batchdatei wird nicht aktualisiert; die PowerShell-Datei ist separat aktualisierbar.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-Dashboard.ps1" %*
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Update nicht abgeschlossen. Hinweise oben pruefen.
pause
exit /b %result%
