#!/usr/bin/env python3

import sys
import os
import json
import subprocess
import questionary

# --- Constants ---
CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".config", "msc")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

# ANSI color codes
YELLOW = '\033[0;33m'
GREEN = '\033[0;32m'
RED = '\033[0;31m'
NC = '\033[0m' # No Color

# --- Functions ---

def load_config():
    """Loads the configuration from the JSON file."""
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"{RED}Error: Configuration file not found at {CONFIG_FILE}{NC}")
        print("Please run the 'install.sh' script first.")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"{RED}Error: Could not decode JSON from {CONFIG_FILE}.{NC}")
        print("The file might be corrupted.")
        sys.exit(1)

def show_help(texts):
    """Prints the help message using text from the config file."""
    cyan = '\033[0;36m'
    art = r"""
███╗   ███╗   ██████╗    ██████╗
████╗ ████║  ██╔════╝   ██╔════╝
██╔████╔██║  ╚█████╗    ██║
██║╚██╔╝██║   ╚═══██╗   ██║
██║ ╚═╝ ██║  ██████╔╝   ██╚════╝
╚═╝     ╚═╝  ╚═════╝    ╚██████╝
"""
    print(f"{cyan}{art}{NC}")
    print(texts.get('app_description', "A tool to streamline semantic commits."))
    print(f"\n{texts.get('usage_title', 'Usage:')}")
    print(f"  msc add [files..|all|.] - {texts.get('usage_add', 'Add files to stage interactively or directly.')}")
    print(f"  msc commit           - {texts.get('usage_commit', 'Interactively create a semantic commit.')}")
    print(f"  msc push             - {texts.get('usage_push', 'Push commits to the remote repository with a safety check.')}")
    print(f"  msc config --lang <en|pt> - {texts.get('usage_config', 'Change the display language.')}")
    print(f"  msc update           - {texts.get('usage_update', 'Check for new updates.')}")
    print(f"  msc --version, -v    - {texts.get('usage_version', 'Show the current version of the tool.')}")
    print(f"  msc --help           - {texts.get('usage_help', 'Show this help message.')}")

def handle_add(config, texts, add_args):
    """Handles the 'add' command to interactively or directly stage files."""
    try:
        if not add_args:
            # Interactive mode
            result = subprocess.run(
                ['git', 'status', '--porcelain', '--untracked-files=all'],
                capture_output=True, text=True, check=True
            )
            lines = result.stdout.strip().split('\n')
            changed_files = [line[3:] for line in lines if line.startswith(('?? ', ' M '))]
            if not changed_files:
                print(texts.get('no_changed_files', "No new or modified files to add."))
                return
            selected_files = questionary.checkbox(
                texts.get('select_files_to_add', "Select files to stage for commit:"),
                choices=changed_files,
                instruction=texts.get('select_files_instruction', " ")
            ).ask()
            if selected_files:
                for file_path in selected_files:
                    subprocess.run(['git', 'add', file_path], check=True)
                print(GREEN + texts.get('files_added', "Selected files have been staged.") + NC)
        else:
            # Direct mode
            processed_args = ['.' if arg.lower() == 'all' else arg for arg in add_args]
            command = ['git', 'add'] + processed_args
            subprocess.run(command, check=True, capture_output=True)
            files_str = ", ".join(processed_args)
            print(GREEN + texts.get('files_added_direct', "Added to stage: {files}").format(files=files_str) + NC)
    except FileNotFoundError:
        print(f"{RED}Error: 'git' command not found. Is Git installed and in your PATH?{NC}")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"{RED}An error occurred while running git: {e.stderr}{NC}")
        sys.exit(1)
    except (KeyboardInterrupt, TypeError):
        print(f"\n{YELLOW}Operation cancelled by user.{NC}")
        sys.exit(0)

def handle_commit(config, texts):
    """Handles the 'commit' command to create a semantic commit message."""
    try:
        result = subprocess.run(['git', 'diff', '--cached', '--quiet'], capture_output=True, text=True)
        if result.returncode == 0:
            print(YELLOW + texts.get('no_files_to_commit', "Error: No files staged for commit.") + NC)
            return

        print(f"\n{YELLOW}{texts.get('emoji_guide_hint', '# If you have doubts about emojis, look in EmojiFlags.MD')}{NC}")

        lang = config.get("settings", {}).get("language", "en")
        commit_types = config.get('commit_types', [])
        choices = [
            questionary.Choice(
                title=item['names'].get(lang, item['names'].get('en', 'Unnamed Commit Type')),
                value=item['value']
            )
            for item in commit_types if 'names' in item
        ]
        selected_type = questionary.select(
            texts.get('select_commit_type', "Select the commit type:"),
            choices=choices
        ).ask()
        if not selected_type: raise KeyboardInterrupt()
        commit_message = questionary.text(texts.get('commit_message_prompt', "Enter the commit message:")).ask()
        if not commit_message: raise KeyboardInterrupt()
        final_message = f"{selected_type}: {commit_message}"
        subprocess.run(['git', 'commit', '-m', final_message], check=True)
        print(f"\n{GREEN}{texts.get('commit_successful', 'Commit successful!')}{NC}")
    except FileNotFoundError:
        print(f"{RED}Error: 'git' command not found. Is Git installed and in your PATH?{NC}")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"{RED}An error occurred while running git: {e.stderr}{NC}")
        sys.exit(1)
    except (KeyboardInterrupt, TypeError):
        print(f"\n{YELLOW}Operation cancelled by user.{NC}")
        sys.exit(0)

def handle_push(config, texts):
    """Handles the 'push' command with a safety check for main/master branches."""
    try:
        result = subprocess.run(['git', 'branch', '--show-current'], capture_output=True, text=True, check=True)
        branch_name = result.stdout.strip()

        proceed = False
        if branch_name in ['main', 'master']:
            warning_message = texts.get('push_warning', "⚠️ You are about to push to the '{branch_name}' branch. Are you sure?").format(branch_name=branch_name)
            
            confirmation = questionary.select(
                f"{YELLOW}{warning_message}{NC}",
                choices=[
                    questionary.Choice(title=texts.get('push_confirm_yes', "✅ Yes"), value=True),
                    questionary.Choice(title=texts.get('push_confirm_no', "❌ No"), value=False)
                ],
                use_indicator=True
            ).ask()

            if confirmation:
                proceed = True
            else:
                print(YELLOW + texts.get('push_cancelled', "Push operation cancelled.") + NC)
        else:
            proceed = True

        if proceed:
            print(f"Pushing to origin/{branch_name}...")
            push_result = subprocess.run(['git', 'push', '-u', 'origin', branch_name], capture_output=True, text=True)
            if push_result.returncode == 0:
                print(GREEN + texts.get('push_successful', "Push successful!") + NC)
                print(push_result.stdout)
            else:
                print(RED + texts.get('push_failed', "Push operation failed.") + NC)
                print(push_result.stderr)

    except FileNotFoundError:
        print(f"{RED}Error: 'git' command not found. Is Git installed and in your PATH?{NC}")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"{RED}An error occurred while running git: {e.stderr}{NC}")
        sys.exit(1)
    except (KeyboardInterrupt, TypeError):
        print(f"\n{YELLOW}Operation cancelled by user.{NC}")
        sys.exit(0)

def handle_config_flags(args, config, texts):
    """Handles the 'config' command when flags are provided (e.g., --lang)."""
    if not args or len(args) < 2 or args[0] != '--lang':
        print("Usage: msc config --lang <en|pt>")
        return
    new_lang = args[1]
    if new_lang not in config.get('texts', {}):
        print(f"{RED}Error: Language '{new_lang}' is not supported.{NC}")
        print("Supported languages are: " + ", ".join(config.get('texts', {}).keys()))
        return
    try:
        config['settings']['language'] = new_lang
        save_config(config)
        print(f"{GREEN}Language successfully changed to '{new_lang}'.{NC}")
    except Exception as e:
        print(f"{RED}An error occurred while writing to the config file: {e}{NC}")
        sys.exit(1)

def handle_interactive_language_change(config, texts):
    """Handles interactive language change."""
    supported_languages = list(config.get('texts', {}).keys())
    new_lang = questionary.select(
        texts.get('config_menu_lang_select', "Select a new language:"),
        choices=supported_languages
    ).ask()
    if new_lang:
        try:
            config['settings']['language'] = new_lang
            save_config(config)
            # We need to get the success message from the *new* language's text map
            new_texts = config.get('texts', {}).get(new_lang, {})
            success_message = new_texts.get('config_menu_lang_success', "Language successfully changed to '{lang}'.")
            print(f"{GREEN}{success_message.format(lang=new_lang)}{NC}")
        except Exception as e:
            print(f"{RED}An error occurred while writing to the config file: {e}{NC}")
            sys.exit(1)

def save_config(config_data):
    """Saves the configuration to the JSON file."""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config_data, f, indent=2)
    except Exception as e:
        print(f"{RED}Error saving configuration: {e}{NC}")
        sys.exit(1)

def get_commit_type_choices(config, texts, include_back=False):
    """Helper to get formatted choices for commit types."""
    lang = config.get("settings", {}).get("language", "en")
    commit_types = config.get('commit_types', [])
    choices = []
    for item in commit_types:
        if 'names' in item:
            title = item['names'].get(lang, item['names'].get('en', 'Unnamed Commit Type'))
            choices.append(questionary.Choice(title=f"{item['value']} {title}", value=item['value']))
    if include_back:
        choices.append(questionary.Choice(title=texts.get('commit_edit_menu_back', "Back"), value="back"))
    return choices

def validate_emoji(emoji_code):
    """Basic validation for emoji code format."""
    return emoji_code.startswith(':') and emoji_code.endswith(':') and len(emoji_code) > 2

def preview_and_confirm_changes(original_config, new_config, texts):
    """Displays a preview of changes and asks for confirmation to save."""
    print(f"\n{YELLOW}{texts.get('commit_preview_title', 'Changes Preview:')}{NC}")
    
    # Simplified preview for now, just showing the new state
    # A full diff is complex for JSON in a CLI
    print(f"{texts.get('commit_preview_new', 'New:')}")
    
    # Find the commit_types array in both configs
    original_types = original_config.get('commit_types', [])
    new_types = new_config.get('commit_types', [])

    # Print a simplified view of the new commit types
    lang = new_config.get("settings", {}).get("language", "en")
    for item in new_types:
        if 'names' in item:
            title = item['names'].get(lang, item['names'].get('en', 'Unnamed Commit Type'))
            print(f"  - {item['value']} {title}")
    
    confirm = questionary.confirm(texts.get('commit_save_confirm', "Save these changes?")).ask()
    return confirm

def add_commit_type(config, texts):
    """Interactively adds a new commit type."""
    print(f"\n{YELLOW}{texts.get('emoji_guide_hint', '# If you have doubts about emojis, look in EmojiFlags.MD')}{NC}")
    
    emoji = questionary.text(texts.get('commit_add_emoji_prompt', "Enter emoji code (e.g., :sparkles:):")).ask()
    if not emoji: return
    if not validate_emoji(emoji):
        print(f"{RED}{texts.get('commit_invalid_emoji', 'Invalid emoji code.')}{NC}")
        return

    commit_type = questionary.text(texts.get('commit_add_type_prompt', "Enter commit type (e.g., feat, fix):")).ask()
    if not commit_type: return
    
    # Check if type already exists
    for item in config.get('commit_types', []):
        if item.get('value', '').endswith(f" {commit_type}"): # Check if value ends with " type"
            print(f"{RED}{texts.get('commit_type_exists', 'Commit type already exists.').format(type=commit_type)}{NC}")
            return

    desc_en = questionary.text(texts.get('commit_add_desc_en_prompt', "Enter English description:")).ask()
    if not desc_en: return
    desc_pt = questionary.text(texts.get('commit_add_desc_pt_prompt', "Enter Portuguese description:")).ask()
    if not desc_pt: return

    new_item = {
        "value": f"{emoji} {commit_type}",
        "names": {
            "en": f"{commit_type}: {desc_en}",
            "pt": f"{commit_type}: {desc_pt}"
        }
    }
    
    new_config = config.copy()
    new_config['commit_types'] = new_config.get('commit_types', []) + [new_item]

    if preview_and_confirm_changes(config, new_config, texts):
        save_config(new_config)
        print(GREEN + texts.get('commit_add_success', "Commit type added successfully!") + NC)
    else:
        print(YELLOW + texts.get('commit_changes_discarded', "Changes discarded.") + NC)

def edit_commit_type(config, texts):
    """Interactively edits an existing commit type."""
    if not config.get('commit_types'):
        print(YELLOW + texts.get('commit_no_types', "No commit types defined.") + NC)
        return

    choices = get_commit_type_choices(config, texts)
    selected_value = questionary.select(
        texts.get('commit_edit_select', "Select commit type to edit:"),
        choices=choices
    ).ask()

    if not selected_value: return

    original_item = next((item for item in config['commit_types'] if item['value'] == selected_value), None)
    if not original_item:
        print(f"{RED}{texts.get('commit_type_not_found', 'Commit type not found.')}{NC}")
        return

    print(f"\n{YELLOW}Editing: {original_item['value']}{NC}")
    print(f"{YELLOW}{texts.get('emoji_guide_hint', '# If you have doubts about emojis, look in EmojiFlags.MD')}{NC}")

    # Pre-fill with current values
    current_emoji = original_item['value'].split(' ')[0] if ' ' in original_item['value'] else ''
    current_type = original_item['value'].split(' ')[1] if ' ' in original_item['value'] else original_item['value']
    current_desc_en = original_item['names'].get('en', '').split(': ', 1)[1] if ': ' in original_item['names'].get('en', '') else original_item['names'].get('en', '')
    current_desc_pt = original_item['names'].get('pt', '').split(': ', 1)[1] if ': ' in original_item['names'].get('pt', '') else original_item['names'].get('pt', '')

    new_emoji = questionary.text(texts.get('commit_add_emoji_prompt', "Enter emoji code (e.g., :sparkles:):"), default=current_emoji).ask()
    if not new_emoji: return
    if not validate_emoji(new_emoji):
        print(f"{RED}{texts.get('commit_invalid_emoji', 'Invalid emoji code.')}{NC}")
        return

    new_type = questionary.text(texts.get('commit_add_type_prompt', "Enter commit type (e.g., feat, fix):"), default=current_type).ask()
    if not new_type: return

    new_desc_en = questionary.text(texts.get('commit_add_desc_en_prompt', "Enter English description:"), default=current_desc_en).ask()
    if not new_desc_en: return
    new_desc_pt = questionary.text(texts.get('commit_add_desc_pt_prompt', "Enter Portuguese description:"), default=current_desc_pt).ask()
    if not new_desc_pt: return

    updated_item = {
        "value": f"{new_emoji} {new_type}",
        "names": {
            "en": f"{new_type}: {new_desc_en}",
            "pt": f"{new_type}: {new_desc_pt}"
        }
    }

    new_config = config.copy()
    new_config['commit_types'] = [updated_item if item['value'] == selected_value else item for item in config['commit_types']]

    if preview_and_confirm_changes(config, new_config, texts):
        save_config(new_config)
        print(GREEN + texts.get('commit_changes_saved', "Changes saved successfully!") + NC)
    else:
        print(YELLOW + texts.get('commit_changes_discarded', "Changes discarded.") + NC)

def remove_commit_type(config, texts):
    """Interactively removes an existing commit type."""
    if not config.get('commit_types'):
        print(YELLOW + texts.get('commit_no_types', "No commit types defined.") + NC)
        return

    choices = get_commit_type_choices(config, texts)
    selected_value = questionary.select(
        texts.get('commit_remove_select', "Select commit type to remove:"),
        choices=choices
    ).ask()

    if not selected_value: return

    new_config = config.copy()
    new_config['commit_types'] = [item for item in config['commit_types'] if item['value'] != selected_value]

    if preview_and_confirm_changes(config, new_config, texts):
        save_config(new_config)
        print(GREEN + texts.get('commit_remove_success', "Commit type removed successfully!") + NC)
    else:
        print(YELLOW + texts.get('commit_changes_discarded', "Changes discarded.") + NC)

def show_commit_edit_menu(config, texts):
    """Displays the menu for editing commit types."""
    while True:
        choice = questionary.select(
            texts.get('commit_edit_menu_title', "Edit Commit Types Menu"),
            choices=[
                questionary.Choice(title=texts.get('commit_edit_menu_add', "Add New Commit Type"), value="add"),
                questionary.Choice(title=texts.get('commit_edit_menu_edit', "Edit Existing Commit Type"), value="edit"),
                questionary.Choice(title=texts.get('commit_edit_menu_remove', "Remove Commit Type"), value="remove"),
                questionary.Choice(title=texts.get('commit_edit_menu_back', "Back"), value="back")
            ]
        ).ask()

        if choice == "add":
            add_commit_type(config, texts)
            config = load_config() # Reload config after potential changes
            texts = config.get("texts", {}).get(config.get("settings", {}).get("language", "en"), {})
        elif choice == "edit":
            edit_commit_type(config, texts)
            config = load_config() # Reload config after potential changes
            texts = config.get("texts", {}).get(config.get("settings", {}).get("language", "en"), {})
        elif choice == "remove":
            remove_commit_type(config, texts)
            config = load_config() # Reload config after potential changes
            texts = config.get("texts", {}).get(config.get("settings", {}).get("language", "en"), {})
        elif choice == "back" or choice is None: # choice is None if user cancels
            break

def show_config_menu(config, texts):
    """Displays the main interactive configuration menu."""
    while True:
        choice = questionary.select(
            texts.get('config_menu_title', "Configuration Menu"),
            choices=[
                questionary.Choice(title=texts.get('config_menu_lang', "Change Language"), value="lang"),
                questionary.Choice(title=texts.get('config_menu_commits', "Edit Commit Types"), value="commits"),
                questionary.Choice(title=texts.get('config_menu_exit', "Exit"), value="exit")
            ]
        ).ask()

        if choice == "lang":
            handle_interactive_language_change(config, texts)
            config = load_config() # Reload config and texts after language change
            texts = config.get("texts", {}).get(config.get("settings", {}).get("language", "en"), {})
        elif choice == "commits":
            show_commit_edit_menu(config, texts)
            config = load_config() # Reload config and texts after commit type changes
            texts = config.get("texts", {}).get(config.get("settings", {}).get("language", "en"), {})
        elif choice == "exit" or choice is None: # choice is None if user cancels
            break

def handle_version(config):
    """Prints the current version of the tool."""
    version = config.get('version', 'N/A')
    print(f"msc version {version}")

def handle_update(config, texts):
    """Checks for a new version and attempts to automatically update."""
    print(texts.get('checking_for_updates', "Checking for updates..."))
    import urllib.request
    repo_url = config.get('repository_url')
    if not repo_url:
        print(f"{RED}Error: Repository URL not configured.{NC}")
        return
    raw_url = repo_url.replace('github.com', 'raw.githubusercontent.com') + '/main/config.json'
    try:
        with urllib.request.urlopen(raw_url) as response:
            remote_data = response.read()
            remote_config = json.loads(remote_data)
        remote_version = remote_config.get('version')
        local_version = config.get('version')
        if not remote_version or not local_version:
            print("Could not determine version from local or remote config.")
            return
        if remote_version > local_version:
            repo_path = config.get('repository_path')
            if not repo_path or not os.path.isdir(repo_path):
                print(texts.get('new_version_available', "New version available!").format(
                    remote_version=remote_version, 
                    repo_url=repo_url
                ))
                return
            print(texts.get('attempting_auto_update', "Attempting automatic update..."))
            try:
                status_result = subprocess.run(
                    ['git', '-C', repo_path, 'status', '--porcelain'],
                    capture_output=True, text=True, check=True
                )
                if status_result.stdout.strip():
                    print(YELLOW + texts.get('local_changes_detected', "Local changes detected. Please commit or stash them before updating.") + NC)
                    sys.exit(1)
                print(f"Running 'git pull' in '{repo_path}'...")
                subprocess.run(['git', '-C', repo_path, 'pull'], check=True, capture_output=True)
                print("Re-running installer...")
                installer_path = os.path.join(repo_path, 'install.sh')
                subprocess.run(['bash', installer_path], check=True, cwd=repo_path, capture_output=True)
                print(GREEN + texts.get('update_complete', "Update complete!") + NC)
                print(f"msc has been updated to version {remote_version}.")
            except Exception as e:
                print(RED + texts.get('update_failed', "Automatic update failed. Please update manually.") + NC)
        else:
            print(GREEN + texts.get('up_to_date', "You are already using the latest version.") + NC)
    except Exception as e:
        print(RED + texts.get('update_check_failed', "Failed to check for updates.") + NC)

def main():
    """Main function to parse arguments and execute commands."""
    config = load_config()
    lang = config.get("settings", {}).get("language", "en")
    texts = config.get("texts", {}).get(lang, {})
    if not texts:
        print(f"{RED}Error: Language texts not found in config. Please check your configuration file.{NC}")
        sys.exit(1)
    args = sys.argv[1:]
    if not args or "--help" in args:
        show_help(texts)
        sys.exit(0)
    command = args[0]
    if command == "add":
        handle_add(config, texts, args[1:])
    elif command == "commit":
        handle_commit(config, texts)
    elif command == "push":
        handle_push(config, texts)
    elif command == "config":
        if len(args) > 1:
            handle_config_flags(args[1:], config, texts)
        else:
            show_config_menu(config, texts)
    elif command == "update":
        handle_update(config, texts)
    elif command == "--version" or command == "-v":
        handle_version(config)
    else:
        print(f"{RED}Error: Unknown command '{command}'{NC}")
        show_help(texts)
        sys.exit(1)

if __name__ == "__main__":
    main()
