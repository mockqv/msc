@echo off
setlocal

:: --- UI Configuration ---
set "CYAN=[0;36m"
set "RED=[0;31m"
set "GREEN=[0;32m"
set "NC=[0m"
set "ERROR_PREFIX=%RED%X %NC%"
set "SUCCESS_PREFIX=%GREEN%v %NC%"

echo %CYAN%Welcome to the My Semantic Commit (MSC) installer for Windows!%NC%
echo.

:: --- Prerequisite Checks ---
echo 1. Checking for prerequisites...
where py >nul 2>nul
if %errorlevel% neq 0 (
    echo %ERROR_PREFIX%Python is not installed.
    echo Please install Python from python.org and run this installer again.
    exit /b 1
)
echo %SUCCESS_PREFIX%Prerequisites are satisfied.
echo.

:: --- Main Installation ---
echo 2. Installing dependencies...
py -m pip install -r requirements.txt --quiet
echo.

echo 3. Configuring settings...
set "MSC_REPO_PATH=%cd%"
py setup_config.py
echo.

echo 4. Adding 'msc' function to PowerShell profile...
set "PYTHON_SCRIPT_PATH=%cd%\main.py"
:: Powershell requires backslashes to be escaped in the function definition string
set "ESCAPED_PATH=%PYTHON_SCRIPT_PATH:\=\\%"

set "POWERSHELL_FUNCTION=function msc { py '%ESCAPED_PATH%' $args }"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$profilePath = $PROFILE; if (-not (Test-Path $profilePath)) { New-Item -Path $profilePath -ItemType File -Force }; $funcDef = '%POWERSHELL_FUNCTION%'; if (-not (Select-String -Path $profilePath -Pattern 'function msc')) { Add-Content -Path $profilePath -Value $funcDef; echo '%SUCCESS_PREFIX%''msc'' function added to your PowerShell profile.'; } else { echo '%CYAN%INFO: ''msc'' function already exists in your PowerShell profile.%NC%'; }"
echo.

echo %SUCCESS_PREFIX%%GREEN%Installation successful!%NC%
echo %RED%You MUST restart your terminal for the 'msc' command to be available.%NC%
echo Try running: msc --help

endlocal
pause