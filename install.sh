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
python3 setup_config.py


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

