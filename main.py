#!/usr/bin/env python3

import sys
import os
import json
import subprocess
import questionary

# --- Constants ---
CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".config", "msc")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

# --- Functions ---

def load_config():
    """Loads the configuration from the JSON file."""
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: Configuration file not found at {CONFIG_FILE}")
        print("Please run the 'install.sh' script first.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from {CONFIG_FILE}.")
        print("The file might be corrupted.")
        sys.exit(1)

def show_help(texts):
    """Prints the help message."""
    print("MSC - My Semantic Commit")
    print("A tool to streamline semantic commits.")
    print("\nUsage:")
    print("  msc add              - Interactively select untracked files to stage.")
    print("  msc commit           - Interactively create a semantic commit.")
    print("  msc config --lang <en|pt> - Change the display language.")
    print("  msc --help           - Show this help message.")

def handle_add(config, texts):
    """Placeholder for the 'add' command functionality."""
    print("'add' command is not yet implemented.")

def handle_commit(config, texts):
    """Placeholder for the 'commit' command functionality."""
    print("'commit' command is not yet implemented.")

def handle_config(args, config, texts):
    """Placeholder for the 'config' command functionality."""
    print("'config' command is not yet implemented.")


def main():
    """Main function to parse arguments and execute commands."""
    config = load_config()
    lang = config.get("settings", {}).get("language", "en")
    texts = config.get("texts", {}).get(lang, {})

    if not texts:
        print("Error: Language texts not found in config. Please check your configuration file.")
        sys.exit(1)

    args = sys.argv[1:]

    if not args or "--help" in args:
        show_help(texts)
        sys.exit(0)

    command = args[0]

    if command == "add":
        handle_add(config, texts)
    elif command == "commit":
        handle_commit(config, texts)
    elif command == "config":
        handle_config(args[1:], config, texts)
    else:
        print(f"Error: Unknown command '{command}'")
        show_help(texts)
        sys.exit(1)

if __name__ == "__main__":
    main()