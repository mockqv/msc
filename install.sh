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

echo "3. Configuring language and settings..."
export MSC_REPO_PATH=$(pwd)
python3 -c "
import questionary
import json
import os
import shutil

# --- Configuration ---
CONFIG_DIR = os.path.join(os.path.expanduser('~'), '.config', 'msc')
CONFIG_FILE = os.path.join(CONFIG_DIR, 'config.json')
SOURCE_CONFIG_FILE = 'config.json'

try:
    # --- Create directory and copy initial config ---
    os.makedirs(CONFIG_DIR, exist_ok=True)
    shutil.copy(SOURCE_CONFIG_FILE, CONFIG_FILE)

    # --- Ask user for language ---
    lang_map = {'🇺🇸 English': 'en', '🇧🇷 Português': 'pt'}
    choice = questionary.select(
        'Please choose your language:',
        choices=list(lang_map.keys())
    ).ask()

    selected_lang = 'en' # Default to English on cancel (choice is None)
    if choice is not None:
        selected_lang = lang_map.get(choice, 'en')

    print(f\"Language set to '{selected_lang}'.\")

    # --- Update the config file with language and repo path ---
    repo_path = os.environ.get('MSC_REPO_PATH', '')
    with open(CONFIG_FILE, 'r+') as f:
        config_data = json.load(f)
        config_data['settings']['language'] = selected_lang
        if repo_path:
            config_data['repository_path'] = repo_path
        f.seek(0)
        json.dump(config_data, f, indent=2)
        f.truncate()
    
    print('Configuration file updated with repository path.')

except (KeyboardInterrupt, TypeError):
    print('\nInstallation cancelled by user.')
    exit(1)
except Exception as e:
    print(f'\nAn unexpected error occurred: {e}')
    exit(1)
"

echo "4. Making the main script executable..."
chmod +x "$MAIN_SCRIPT"

echo "5. Installing the 'msc' command..."
if [ -w "$INSTALL_DIR" ]; then
    echo "Installing for current user in $INSTALL_DIR..."
    cp "$MAIN_SCRIPT" "$INSTALL_DIR/$CMD_NAME"
else
    echo "Administrator privileges are required to install in $INSTALL_DIR."
    sudo cp "$MAIN_SCRIPT" "$INSTALL_DIR/$CMD_NAME"
fi

echo -e "\n${SUCCESS_PREFIX}Installation successful!"
echo "You can now use the '$CMD_NAME' command from anywhere in your terminal."
echo "Try running: msc --help"
