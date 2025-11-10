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

:: 1. Remove the 'msc' function from the PowerShell profile
echo 1. Removing 'msc' function from PowerShell profile...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profilePath = $PROFILE; if (Test-Path $profilePath) { $profileContent = Get-Content $profilePath; $newProfileContent = $profileContent | Where-Object { $_ -notmatch 'function msc' }; Set-Content -Path $profilePath -Value $newProfileContent; echo '   SUCCESS: ''msc'' function removed from profile.'; } else { echo '   INFO: PowerShell profile not found, skipping.'; }"
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
py -m pip uninstall -y questionary --quiet
echo    Dependencies uninstalled.
echo.

echo %SUCCESS_PREFIX%%CYAN%MSC has been successfully uninstalled from your system.%NC%
echo %RED%Please restart your terminal for the changes to take effect.%NC%
echo.

endlocal
pause
