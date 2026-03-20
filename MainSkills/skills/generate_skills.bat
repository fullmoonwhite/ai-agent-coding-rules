@echo off
chcp 65001 > nul
echo [INFO] generate_skills : starting...

where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] generate_skills : PowerShell not found.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0generate_skills.ps1" %*
if %errorlevel% neq 0 (
    echo [ERROR] generate_skills : script failed.
    pause
    exit /b 1
)

echo [INFO] generate_skills : done.
