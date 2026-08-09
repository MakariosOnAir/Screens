@echo off
title St-Philopateer Screens Launcher

echo Opening screens display in default browser...
start "" "https://st-philopateer-screens.fly.dev/screens"

echo Preparing companion script...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://st-philopateer-screens.fly.dev/companion.ps1' -OutFile '%TEMP%\companion.ps1'"

if not exist "%TEMP%\companion.ps1" goto error

echo Set WshShell = CreateObject("WScript.Shell") > "%TEMP%\launch.vbs"
echo WshShell.Run "powershell -ExecutionPolicy Bypass -File ""%TEMP%\companion.ps1""", 0, false >> "%TEMP%\launch.vbs"
wscript "%TEMP%\launch.vbs"
del "%TEMP%\launch.vbs"
exit

:error
echo Error: Failed to download companion script. Please check your internet connection.
pause
exit
