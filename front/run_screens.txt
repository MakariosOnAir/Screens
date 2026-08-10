@echo off
title St-Philopateer Screens Launcher

echo Opening screens display in kiosk fullscreen mode...
:: CHANGEME: Put your Netlify URL here
set "URL=YOUR_NETLIFY_URL"

if exist "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" --kiosk --user-data-dir="%TEMP%\BraveKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk --user-data-dir="%TEMP%\ChromeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --kiosk --user-data-dir="%TEMP%\ChromeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --kiosk --user-data-dir="%TEMP%\EdgeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files\Microsoft\Edge\Application\msedge.exe" --kiosk --user-data-dir="%TEMP%\EdgeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe" --kiosk --user-data-dir="%TEMP%\BraveKioskProfile" "%URL%"
    goto next
)

:: Fallback if no known browser found
start "" "%URL%"

:next
echo Preparing companion script...
set "SCRIPT_PATH=%~dp0companion.ps1"

if not exist "%SCRIPT_PATH%" goto error

echo Set WshShell = CreateObject("WScript.Shell") > "%TEMP%\launch.vbs"
echo WshShell.Run "powershell -ExecutionPolicy Bypass -File ""%SCRIPT_PATH%""", 0, false >> "%TEMP%\launch.vbs"
wscript "%TEMP%\launch.vbs"
del "%TEMP%\launch.vbs"
exit

:error
echo Error: companion.ps1 not found in the same folder as this launcher.
pause
exit
