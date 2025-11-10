@echo off
setlocal

:: --- UI Configuration ---
set "RED=[0;31m"
set "CYAN=[0;36m"
set "NC=[0m"
set "SUCCESS_PREFIX=v "

echo %CYAN%Starting the uninstallation of MSC...%NC%
echo.

:: --- Uninstallation Steps ---

:: 1. Remove the main command
echo 1. Removing 'msc' command...
for /f "delims=" %%i in ('python -m site --user-scripts') do set "USER_SCRIPTS=%%i"
if exist "%USER_SCRIPTS%\msc.bat" (
    del "%USER_SCRIPTS%\msc.bat"
    echo    'msc' command removed.
) else (
    echo    'msc' command not found, skipping.
)
echo.

:: 2. Remove the configuration directory
echo 2. Removing configuration directory...
if exist "%APPDATA%\msc" (
    rmdir /s /q "%APPDATA%\msc"
    echo    Configuration directory removed.
) else (
    echo    Configuration directory not found, skipping.
)
echo.

:: 3. Uninstall the Python dependency
echo 3. Uninstalling Python dependencies...
pip uninstall -y questionary --quiet
echo    Dependencies uninstalled.
echo.

echo %SUCCESS_PREFIX%%CYAN%MSC has been successfully uninstalled from your system.%NC%
echo.

endlocal
pause
