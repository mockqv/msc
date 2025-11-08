#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- UI Configuration ---
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
SUCCESS_PREFIX="✅ "

echo -e "${CYAN}Starting the uninstallation of MSC...${NC}\n"

# --- Uninstallation Steps ---

# 1. Remove the main command from /usr/local/bin
echo "1. Removing 'msc' command..."
if [ -f "/usr/local/bin/msc" ]; then
    sudo rm /usr/local/bin/msc
    echo "   'msc' command removed."
else
    echo "   'msc' command not found, skipping."
fi

# 2. Remove the configuration directory from ~/.config
echo "2. Removing configuration directory..."
if [ -d "$HOME/.config/msc" ]; then
    rm -rf "$HOME/.config/msc"
    echo "   Configuration directory removed."
else
    echo "   Configuration directory not found, skipping."
fi

# 3. Uninstall the Python dependency
echo "3. Uninstalling Python dependencies..."
# The -y flag confirms the uninstallation without a prompt
pip3 uninstall -y questionary --quiet
echo "   Dependencies uninstalled."


echo -e "\n${SUCCESS_PREFIX}MSC has been successfully uninstalled from your system.${NC}"
