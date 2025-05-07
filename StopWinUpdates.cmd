@echo off
setlocal

:: Set path to PowerShell script in script folder
set scriptPath=%~dp0script\UpdateController.ps1

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%scriptPath%"

pause