#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- UI Configuration ---
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color
ERROR_PREFIX="${RED}❌ "
SUCCESS_PREFIX="✅ "

# --- Script Configuration ---
INSTALL_DIR="/usr/local/bin"
CMD_NAME="msc"
MAIN_SCRIPT="main.py"

# --- Welcome Message ---
cat << "EOF"

███╗   ███╗   ██████╗    ██████╗
████╗ ████║  ██╔════╝   ██╔════╝
██╔████╔██║  ╚█████╗    ██║
██║╚██╔╝██║   ╚═══██╗   ██║
██║ ╚═╝ ██║  ██████╔╝   ██╚════╝
╚═╝     ╚═╝  ╚═════╝    ╚██████╝

EOF
echo -e "${CYAN}Welcome to the My Semantic Commit (MSC) installer!${NC}\n"

# --- Prerequisite Checks ---
echo "1. Checking for prerequisites..."

# Check for Git
if ! command -v git &> /dev/null; then
    echo -e "${ERROR_PREFIX}Git is not installed. Git is required for this tool to work.${NC}"
    echo "Please install Git and run this installer again."
    exit 1
fi

# Check for Python & Pip
if ! command -v python3 &> /dev/null || ! (command -v pip &> /dev/null || command -v pip3 &> /dev/null); then
    echo -e "${ERROR_PREFIX}Python 3 and/or Pip are not installed.${NC}"
    while true; do
        read -p "Do you want to attempt to install them now? (y/n) " yn
        case $yn in
            [Yy]* )
                if command -v apt-get &> /dev/null; then
                    echo "Attempting to install using apt-get. This requires administrator privileges."
                    sudo apt-get update
                    sudo apt-get install -y python3 python3-pip
                    echo "Installation attempt finished. Re-running prerequisite check..."
                    break
                else
                    echo -e "${ERROR_PREFIX}Your OS package manager is not supported for automatic installation.${NC}"
                    echo "Please install Python 3 and Pip manually, then run this script again."
                    exit 1
                fi
                ;;
            [Nn]* )
                echo "Installation cancelled."
                exit
                ;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
fi

# Re-check after potential installation
if ! command -v python3 &> /dev/null || ! (command -v pip &> /dev/null || command -v pip3 &> /dev/null); then
     echo -e "${ERROR_PREFIX}Installation failed or was skipped. Cannot proceed.${NC}"
     echo "Please install Python 3 and Pip manually, then run this script again."
     exit 1
fi

echo -e "${SUCCESS_PREFIX}Prerequisites are satisfied.\n"

# --- Main Installation ---
echo "2. Installing dependencies..."
pip3 install -r requirements.txt --quiet

echo "3. Checking permissions and updating sudo timestamp..."
# Prompt for sudo password upfront and refresh timestamp
sudo -v

echo "4. Configuring settings..."
export MSC_REPO_PATH=$(pwd)
python3 -c "
import json
import os
import shutil
import questionary
from collections.abc import MutableMapping

def deep_update(d, u):
    \"\"
    Recursively update a dictionary 'd' with values from 'u'.
    If a key in 'u' is a dictionary, it recursively updates the corresponding key in 'd'.
    Otherwise, it just sets the value.
    \"\"
    for k, v in u.items():
        if isinstance(v, MutableMapping):
            d[k] = deep_update(d.get(k, {}), v)
        else:
            d[k] = v
    return d

# --- Configuration ---
CONFIG_DIR = os.path.join(os.path.expanduser('~'), '.config', 'msc')
USER_CONFIG_FILE = os.path.join(CONFIG_DIR, 'config.json')
REPO_CONFIG_FILE = 'config.json'

os.makedirs(CONFIG_DIR, exist_ok=True)

try:
    with open(REPO_CONFIG_FILE, 'r') as f:
        repo_config = json.load(f)
    
    # Get the installer texts from the repo config first
    # Default to English if the 'installer_language_prompt' key is missing
    lang = repo_config.get('settings', {}).get('language', 'en')
    texts = repo_config.get('texts', {}).get(lang, repo_config.get('texts', {}).get('en', {}))

    if os.path.exists(USER_CONFIG_FILE):
        # --- Merge existing config ---
        print(texts.get('installer_config_merged', 'Existing configuration found. Merging new settings.'))
        with open(USER_CONFIG_FILE, 'r') as f:
            user_config = json.load(f)

        # Preserve user's custom settings and commit types
        repo_config['settings'] = user_config.get('settings', repo_config['settings'])
        repo_config['commit_types'] = user_config.get('commit_types', repo_config['commit_types'])
        
        # Deep update texts to add new translations without overwriting user changes
        # The default texts (from repo) are used as the base
        merged_texts = deep_update(repo_config['texts'], user_config.get('texts', {}))
        repo_config['texts'] = merged_texts

        # Update repository path
        repo_config['repository_path'] = os.environ.get('MSC_REPO_PATH', '')

        # Write the merged config back
        with open(USER_CONFIG_FILE, 'w') as f:
            json.dump(repo_config, f, indent=2)
        print(texts.get('installer_config_updated', 'Configuration file updated.'))

    else:
        # --- First-time setup ---
        shutil.copy(REPO_CONFIG_FILE, USER_CONFIG_FILE)
        
        lang_map = {'🇺🇸 English': 'en', '🇧🇷 Português': 'pt'}
        prompt_text = texts.get('installer_language_prompt', 'Please choose your language:')
        choice = questionary.select(
            prompt_text,
            choices=list(lang_map.keys())
        ).ask()

        selected_lang = 'en'
        if choice:
            selected_lang = lang_map.get(choice, 'en')

        print(texts.get('installer_language_set', 'Language set to ''{lang}''.').format(lang=selected_lang))

        with open(USER_CONFIG_FILE, 'r+') as f:
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

echo "5. Making the main script executable..."
chmod +x "$MAIN_SCRIPT"

echo "6. Installing the 'msc' command..."
if [ -w "$INSTALL_DIR" ]; then
    cp "$MAIN_SCRIPT" "$INSTALL_DIR/$CMD_NAME"
else
    echo "Administrator privileges are required to install in $INSTALL_DIR."
    sudo cp "$MAIN_SCRIPT" "$INSTALL_DIR/$CMD_NAME"
fi

# Load texts for final messages
FINAL_LANG=$(python3 -c "import json, os; f=open(os.path.join(os.path.expanduser('~'), '.config', 'msc', 'config.json')); d=json.load(f); print(d.get('settings', {}).get('language', 'en'))")
SUCCESS_MSG=$(python3 -c "import json, os; f=open('config.json'); d=json.load(f); print(d.get('texts', {}).get('$FINAL_LANG', {}).get('installer_success', 'Installation successful!'))")
FINISHED_MSG=$(python3 -c "import json, os; f=open('config.json'); d=json.load(f); print(d.get('texts', {}).get('$FINAL_LANG', {}).get('installer_finished', 'You can now use the ''msc'' command from anywhere in your terminal.'))")
TRY_MSG=$(python3 -c "import json, os; f=open('config.json'); d=json.load(f); print(d.get('texts', {}).get('$FINAL_LANG', {}).get('installer_try', 'Try running: msc --help'))")

echo -e "\n${SUCCESS_PREFIX}${SUCCESS_MSG}"
echo "${FINISHED_MSG}"
echo "${TRY_MSG}"

