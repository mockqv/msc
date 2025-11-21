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
    # Arch/CachyOS check
    if command -v pacman &> /dev/null; then
         echo "Detected Arch-based system (pacman). Attempting to install git..."
         sudo pacman -S --noconfirm git
    else
         echo "Please install Git and run this installer again."
         exit 1
    fi
fi

# Check for Python & Pip
if ! command -v python3 &> /dev/null || ! (command -v pip &> /dev/null || command -v pip3 &> /dev/null); then
    echo -e "${ERROR_PREFIX}Python 3 and/or Pip are not installed.${NC}"
    while true; do
        read -p "Do you want to attempt to install them now? (y/n) " yn
        case $yn in
            [Yy]* )
                if command -v pacman &> /dev/null; then
                    # Arch / CachyOS Support
                    echo "Detected Arch-based system. Installing dependencies via pacman..."
                    sudo pacman -S --noconfirm python python-pip
                    echo "Installation attempt finished. Re-running prerequisite check..."
                    break
                elif command -v apt-get &> /dev/null; then
                    # Debian / Ubuntu Support
                    echo "Attempting to install using apt-get..."
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
if ! command -v python3 &> /dev/null; then
     echo -e "${ERROR_PREFIX}Installation failed or was skipped. Cannot proceed.${NC}"
     exit 1
fi

echo -e "${SUCCESS_PREFIX}Prerequisites are satisfied.\n"

# --- Main Installation ---
echo "2. Installing Python libraries..."
# Try installing with break-system-packages if on newer Arch/Python versions managed by pacman
pip3 install -r requirements.txt --quiet --break-system-packages 2>/dev/null || pip3 install -r requirements.txt --quiet

echo "3. Checking permissions and updating sudo timestamp..."
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

# Ensure the destination is executable
sudo chmod +x "$INSTALL_DIR/$CMD_NAME"

# Load texts for final messages
FINAL_LANG=$(python3 -c "import json, os; f=open(os.path.join(os.path.expanduser('~'), '.config', 'msc', 'config.json')); d=json.load(f); print(d.get('settings', {}).get('language', 'en'))")
SUCCESS_MSG=$(python3 -c "import json, os; f=open('config.json'); d=json.load(f); print(d.get('texts', {}).get('$FINAL_LANG', {}).get('installer_success', 'Installation successful!'))")
FINISHED_MSG=$(python3 -c "import json, os; f=open('config.json'); d=json.load(f); print(d.get('texts', {}).get('$FINAL_LANG', {}).get('installer_finished', 'You can now use the ''msc'' command from anywhere in your terminal.'))")
TRY_MSG=$(python3 -c "import json, os; f=open('config.json'); d=json.load(f); print(d.get('texts', {}).get('$FINAL_LANG', {}).get('installer_try', 'Try running: msc --help'))")

echo -e "\n${SUCCESS_PREFIX}${SUCCESS_MSG}"
echo "${FINISHED_MSG}"
echo "${TRY_MSG}"