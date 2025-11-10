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

echo 4. Creating the 'msc' command...
:: Find user scripts path and create the command
for /f "delims=" %%i in ('py -m site --user-scripts') do set "USER_SCRIPTS=%%i"

:: Verify that the path was found
if not defined USER_SCRIPTS (
    echo %ERROR_PREFIX%Could not determine Python scripts directory.
    echo Installation cannot continue.
    exit /b 1
)

if not exist "%USER_SCRIPTS%" (
    mkdir "%USER_SCRIPTS%"
)
set "CMD_FILE=%USER_SCRIPTS%\msc.bat"
(
    echo @echo off
    echo py "%MSC_REPO_PATH%\main.py" %*
) > "%CMD_FILE%"
echo %SUCCESS_PREFIX%'msc' command created successfully.
echo.

echo 5. Verifying and updating PATH...
:: Check if the user scripts directory is in the PATH
echo %PATH% | find /i "%USER_SCRIPTS%" >nul
if %errorlevel% neq 0 (
    echo %CYAN%Attempting to add the scripts directory to your user PATH...%NC%
    echo.
    setx PATH "%PATH%;%USER_SCRIPTS%"
    echo.
    echo %RED%IMPORTANT:%NC% The PATH has been updated for future terminal sessions.
    echo Please close and reopen this terminal for the 'msc' command to work.
) else (
    echo %SUCCESS_PREFIX%Scripts directory is already in your PATH.
)
echo.

echo %SUCCESS_PREFIX%%GREEN%Installation successful!%NC%
echo You can now use the 'msc' command from anywhere in your terminal.
echo Try running: msc --help

endlocal
pause
