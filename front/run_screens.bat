@echo off
title St-Philopateer Screens Launcher

echo Opening screens display in default browser...
start "" "https://st-philopateer-screens.fly.dev/screens"

echo Preparing companion script...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://st-philopateer-screens.fly.dev/companion.ps1' -OutFile '%TEMP%\companion.ps1'"

if exist "%TEMP%\companion.ps1" (
    start "" powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%TEMP%\companion.ps1"
) else (
    echo Error: Failed to download companion script. Please check your internet connection.
    pause
)
exit
