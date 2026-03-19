@echo off
chcp 65001 > nul
echo [INFO] generate_index : starting...

where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] generate_index : PowerShell not found.
    echo         Please install PowerShell and try again.
    exit /b 1
)

REM Call powershell script
powershell -ExecutionPolicy Bypass -File "%~dp0generate_index.ps1" %*
if %errorlevel% neq 0 (
    echo [ERROR] generate_index : script failed.
    exit /b 1
)

echo [INFO] generate_index : done.
