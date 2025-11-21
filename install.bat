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
where python >nul 2>nul
if %errorlevel% neq 0 (
    where py >nul 2>nul
    if %errorlevel% neq 0 (
        echo %ERROR_PREFIX%Python is not installed.
        echo Please install Python from python.org and run this installer again.
        exit /b 1
    )
)
echo %SUCCESS_PREFIX%Prerequisites are satisfied.
echo.

:: --- Main Installation ---
echo 2. Installing dependencies...
python -m pip install -r requirements.txt --quiet
echo.

echo 3. Configuring settings...
set "MSC_REPO_PATH=%cd%"
python setup_config.py
echo.

echo 4. creating executable shim (msc.cmd)...
:: Create a .cmd file that handles arguments correctly using %*
:: This works in CMD, PowerShell, and git bash without needing doskey macros
(
echo @echo off
echo python "%%~dp0main.py" %%*
) > msc.cmd

if exist msc.cmd (
    echo %SUCCESS_PREFIX%msc.cmd created successfully.
) else (
    echo %ERROR_PREFIX%Failed to create msc.cmd.
    exit /b 1
)
echo.

echo 5. Updating System PATH...
:: Check if current directory is already in PATH
echo %PATH% | find /i "%cd%" >nul
if %errorlevel% equ 0 (
    echo %CYAN%INFO: Current directory is already in your PATH.%NC%
) else (
    echo Adding "%cd%" to your user PATH variable...
    :: Use setx to add to User Path permanently
    setx PATH "%cd%;%PATH%" >nul
    if %errorlevel% equ 0 (
        echo %SUCCESS_PREFIX%Path updated successfully.
    ) else (
        echo %ERROR_PREFIX%Failed to update PATH. You may need to add it manually.
    )
)
echo.

:: --- Optional: Add to PowerShell profile as backup ---
echo 6. Configuring PowerShell profile (Backup method)...
set "PYTHON_SCRIPT_PATH=%cd%\main.py"
set "ESCAPED_PATH=%PYTHON_SCRIPT_PATH:\=\\%"
:: Using @args in PowerShell is cleaner than the previous method
set "POWERSHELL_FUNCTION=function msc { python '%ESCAPED_PATH%' @args }"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$profilePath = $PROFILE; if (-not (Test-Path $profilePath)) { New-Item -Path $profilePath -ItemType File -Force }; $funcDef = '%POWERSHELL_FUNCTION%'; if (-not (Select-String -Path $profilePath -Pattern 'function msc')) { Add-Content -Path $profilePath -Value $funcDef; echo '%SUCCESS_PREFIX%''msc'' function added to PowerShell profile.'; } else { echo '%CYAN%INFO: ''msc'' function already in profile.%NC%'; }"
echo.

echo %SUCCESS_PREFIX%%GREEN%Installation successful!%NC%
echo %RED%IMPORTANT: You MUST restart your terminal (close and reopen) for the 'msc' command to work.%NC%
echo Try running: msc --help

endlocal
pause