@echo off
title St-Philopateer Screens - Local Server Launcher
cd /d "%~dp0"

echo Starting Local Node.js Server...
:: Start the node server in a minimized window so it stays running but out of the way
start /min "Screens Server" node back/server.js

echo Waiting for server to start...
timeout /t 3 /nobreak > nul

:: Find the local IP address of this computer
for /f "tokens=4 delims= " %%i in ('route print ^| findstr 0.0.0.0 ^| find "Active Routes"') do set LOCAL_IP=%%i

cls
echo ======================================================
echo          St-Philopateer Screens - Local Server
echo ======================================================
echo.
echo Server is running locally on port 7860.
echo.
echo * To open the Admin Panel on THIS computer:
echo   http://localhost:7860/admin
echo.
if not "%LOCAL_IP%"=="" (
    echo * To control screens from your Phone or another PC on the SAME Wi-Fi:
    echo   http://%LOCAL_IP%:7860/admin
    echo.
)
echo ======================================================
echo.

echo Opening screens display in kiosk fullscreen mode...
set "URL=http://localhost:7860/screens"

if exist "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" --kiosk --user-data-dir="%TEMP%\BraveKioskProfile" "%URL%"
    goto launch_companion
)
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk --user-data-dir="%TEMP%\ChromeKioskProfile" "%URL%"
    goto launch_companion
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --kiosk --user-data-dir="%TEMP%\ChromeKioskProfile" "%URL%"
    goto launch_companion
)
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --kiosk --user-data-dir="%TEMP%\EdgeKioskProfile" "%URL%"
    goto launch_companion
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files\Microsoft\Edge\Application\msedge.exe" --kiosk --user-data-dir="%TEMP%\EdgeKioskProfile" "%URL%"
    goto launch_companion
)

:: Fallback if no known browser found
start "" "%URL%"

:launch_companion
echo Starting window companion script...
:: Run the local companion script completely invisibly
echo Set WshShell = CreateObject("WScript.Shell") > "%TEMP%\launch.vbs"
echo WshShell.Run "powershell -ExecutionPolicy Bypass -File ""%~dp0front\companion.ps1""", 0, false >> "%TEMP%\launch.vbs"
wscript "%TEMP%\launch.vbs"
del "%TEMP%\launch.vbs"

echo Launcher finished. Keeping this window open to show IP details.
echo Press any key to close this help window (Server will keep running in background).
pause > nul
exit
