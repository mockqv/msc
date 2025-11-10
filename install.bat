@echo off
setlocal

:: --- UI Configuration ---
set "CYAN=[0;36m"
set "RED=[0;31m"
set "GREEN=[0;32m"
set "NC=[0m"
set "ERROR_PREFIX=%RED%X %NC%"
set "SUCCESS_PREFIX=%GREEN%v %NC%"

:: --- Welcome Message ---
echo.
echo ███╗   ███╗   ██████╗    ██████╗
echo ████╗ ████║  ██╔════╝   ██╔════╝
echo ██╔████╔██║  ╚█████╗    ██║
echo ██║╚██╔╝██║   ╚═══██╗   ██║
echo ██║ ╚═╝ ██║  ██████╔╝   ██╚════╝
echo ╚═╝     ╚═╝  ╚═════╝    ╚██████╝
echo.
echo %CYAN%Welcome to the My Semantic Commit (MSC) installer for Windows!%NC%
echo.

:: --- Prerequisite Checks ---
echo 1. Checking for prerequisites...

:: Check for Git
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo %ERROR_PREFIX%Git is not installed. Git is required for this tool to work.
    echo Please install Git and run this installer again.
    exit /b 1
)

:: Check for Python & Pip
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

echo 4. Creating the 'msc' command in a dedicated directory...
:: Define a reliable installation directory
set "INSTALL_DIR=%LOCALAPPDATA%\msc"

if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)

set "CMD_FILE=%INSTALL_DIR%\msc.bat"
(
    echo @echo off
    echo py "%cd%\main.py" %*
) > "%CMD_FILE%"
echo %SUCCESS_PREFIX%'msc' command created in '%INSTALL_DIR%'.
echo.

echo 5. Verifying and updating PATH...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$scriptsPath = '%INSTALL_DIR%'; $currentUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User'); if (-not ($currentUserPath.Split(';') -contains $scriptsPath)) { $newPath = $currentUserPath + ';' + $scriptsPath; [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User'); echo '%CYAN%SUCCESS: Install directory added to user PATH.%NC%'; echo '%RED%IMPORTANT: Please restart your terminal for the change to take effect.%NC%'; } else { echo '%CYAN%INFO: Install directory already in user PATH.%NC%'; }"
echo.

echo %SUCCESS_PREFIX%%GREEN%Installation successful!%NC%
echo You can now use the 'msc' command from anywhere in your terminal.
echo Try running: msc --help

endlocal
pause
