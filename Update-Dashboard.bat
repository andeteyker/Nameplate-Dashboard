@echo off
setlocal
cd /d "%~dp0"
echo Nameplate Dashboard Updater
rem Updater-Skript aus temporaerer Kopie starten, damit es sich selbst aktualisieren kann.
set "worker=%TEMP%\nameplate-updater-%RANDOM%-%RANDOM%.ps1"
copy /Y "%~dp0Update-Dashboard.ps1" "%worker%" >NUL
if errorlevel 1 (
 echo Update-Dashboard.ps1 konnte nicht kopiert werden.
 pause
 exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%worker%" -InstallDir "%~dp0." %*
set "result=%errorlevel%"
del /Q "%worker%" >NUL 2>&1
echo.
if not "%result%"=="0" echo Update nicht abgeschlossen. Hinweise oben pruefen.
pause
exit /b %result%
