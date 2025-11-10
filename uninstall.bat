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
set "INSTALL_DIR=%LOCALAPPDATA%\msc"

:: 1. Remove the main command
echo 1. Removing 'msc' command file...
if exist "%INSTALL_DIR%\msc.bat" (
    del "%INSTALL_DIR%\msc.bat"
    echo    'msc.bat' command removed.
) else (
    echo    'msc.bat' not found, skipping.
)
echo.

:: 2. Remove the installation directory from PATH
echo 2. Removing installation directory from user PATH...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$installDir = '%INSTALL_DIR%'; $currentUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User'); $pathParts = $currentUserPath.Split(';'); $newPathParts = $pathParts | Where-Object { $_ -ne $installDir }; $newPath = $newPathParts -join ';'; if ($newPath -ne $currentUserPath) { [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User'); echo '   SUCCESS: PATH updated.'; } else { echo '   INFO: Install directory not found in PATH.'; }"
echo.

:: 3. Remove the configuration directory
echo 3. Removing configuration directory...
if exist "%APPDATA%\msc" (
    rmdir /s /q "%APPDATA%\msc"
    echo    Configuration directory removed.
) else (
    echo    Configuration directory not found, skipping.
)
echo.

:: 4. Uninstall the Python dependency
echo 4. Uninstalling Python dependencies...
py -m pip uninstall -y questionary --quiet
echo    Dependencies uninstalled.
echo.

echo %SUCCESS_PREFIX%%CYAN%MSC has been successfully uninstalled from your system.%NC%
echo %RED%Please restart your terminal for the PATH changes to take effect.%NC%
echo.

endlocal
pause