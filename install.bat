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

python -c "
import json
import os
import shutil
import questionary
from collections.abc import MutableMapping

def deep_update(d, u):
    for k, v in u.items():
        if isinstance(v, MutableMapping):
            d[k] = deep_update(d.get(k, {}), v)
        else:
            d[k] = v
    return d

# --- Configuration ---
if os.name == 'nt':
    CONFIG_DIR = os.path.join(os.getenv('APPDATA'), 'msc')
else:
    CONFIG_DIR = os.path.join(os.path.expanduser('~'), '.config', 'msc')

USER_CONFIG_FILE = os.path.join(CONFIG_DIR, 'config.json')
REPO_CONFIG_FILE = 'config.json'

os.makedirs(CONFIG_DIR, exist_ok=True)

try:
    with open(REPO_CONFIG_FILE, 'r', encoding='utf-8') as f:
        repo_config = json.load(f)
    
    lang = repo_config.get('settings', {}).get('language', 'en')
    texts = repo_config.get('texts', {}).get(lang, repo_config.get('texts', {}).get('en', {}))

    if os.path.exists(USER_CONFIG_FILE):
        print(texts.get('installer_config_merged', 'Existing configuration found. Merging new settings.'))
        with open(USER_CONFIG_FILE, 'r', encoding='utf-8') as f:
            user_config = json.load(f)

        repo_config['settings'] = user_config.get('settings', repo_config['settings'])
        repo_config['commit_types'] = user_config.get('commit_types', repo_config['commit_types'])
        
        merged_texts = deep_update(repo_config['texts'], user_config.get('texts', {}))
        repo_config['texts'] = merged_texts

        repo_config['repository_path'] = os.environ.get('MSC_REPO_PATH', '')

        with open(USER_CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(repo_config, f, indent=2)
        print(texts.get('installer_config_updated', 'Configuration file updated.'))

    else:
        shutil.copy(REPO_CONFIG_FILE, USER_CONFIG_FILE)
        
        lang_map = {'🇺🇸 English': 'en', '🇧🇷 Português': 'pt'}
        prompt_text = texts.get('installer_language_prompt', 'Please choose your language:')
        
        # questionary doesn't work well in this context on Windows, so we use a simpler input
        choice = input(f'{prompt_text} (en/pt): ').lower()
        selected_lang = 'pt' if choice == 'pt' else 'en'

        print(texts.get('installer_language_set', 'Language set to ''{lang}''.').format(lang=selected_lang))

        with open(USER_CONFIG_FILE, 'r+', encoding='utf-8') as f:
            config_data = json.load(f)
            config_data['settings']['language'] = selected_lang
            config_data['repository_path'] = os.environ.get('MSC_REPO_PATH', '')
            f.seek(0)
            json.dump(config_data, f, indent=2)
            f.truncate()
        print(texts.get('installer_config_updated', 'Configuration file updated.'))

except (KeyboardInterrupt, TypeError):
    print('\nInstallation cancelled by user.')
    exit(1)
except Exception as e:
    print(f'\nAn unexpected error occurred: {e}')
    exit(1)
"
echo.

echo 4. Creating the 'msc' command...
:: Find user scripts path and create the command
for /f "delims=" %%i in ('python -m site --user-scripts') do set "USER_SCRIPTS=%%i"
if not exist "%USER_SCRIPTS%" (
    mkdir "%USER_SCRIPTS%"
)
set "CMD_FILE=%USER_SCRIPTS%\msc.bat"
(
    echo @echo off
    echo python "%MSC_REPO_PATH%\main.py" %*
) > "%CMD_FILE%"
echo %SUCCESS_PREFIX%'msc' command created successfully.
echo.

echo 5. Verifying PATH...
:: Check if the user scripts directory is in the PATH
echo %PATH% | find /i "%USER_SCRIPTS%" >nul
if %errorlevel% neq 0 (
    echo %RED%Warning: The directory '%USER_SCRIPTS%' is not in your PATH.%NC%
    echo You will need to add it manually to run 'msc' from anywhere.
    echo Or, you can restart your terminal, as some Python installers add it on startup.
) else (
    echo %SUCCESS_PREFIX%Scripts directory is in your PATH.
)
echo.

echo %SUCCESS_PREFIX%%GREEN%Installation successful!%NC%
echo You can now use the 'msc' command from anywhere in your terminal.
echo Try running: msc --help

endlocal
pause
