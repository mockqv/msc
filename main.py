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

    """Prints the help message using text from the config file."""

    # ANSI color codes

    cyan = '\033[0;36m'

    nc = '\033[0m' # No Color



    art = r"""

███╗   ███╗   ██████╗    ██████╗
████╗ ████║  ██╔════╝   ██╔════╝
██╔████╔██║  ╚█████╗    ██║
██║╚██╔╝██║   ╚═══██╗   ██║
██║ ╚═╝ ██║  ██████╔╝   ██╚════╝
╚═╝     ╚═╝  ╚═════╝    ╚██████╝

"""

    print(f"{cyan}{art}{nc}")

    print(texts.get('app_description', "A tool to streamline semantic commits."))

    print(f"\n{texts.get('usage_title', 'Usage:')}")

    print(f"  msc add [files..|all|.] - {texts.get('usage_add', 'Add files to stage interactively or directly.')}")

    print(f"  msc commit           - {texts.get('usage_commit', 'Interactively create a semantic commit.')}")

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

                print(texts.get('files_added', "Selected files have been staged."))

        else:

            # Direct mode

            processed_args = ['.' if arg.lower() == 'all' else arg for arg in add_args]

            command = ['git', 'add'] + processed_args

            subprocess.run(command, check=True, capture_output=True)

            files_str = ", ".join(processed_args)

            print(texts.get('files_added_direct', "Added to stage: {files}").format(files=files_str))



    except FileNotFoundError:

        print("Error: 'git' command not found. Is Git installed and in your PATH?")

        sys.exit(1)

    except subprocess.CalledProcessError as e:

        print(f"An error occurred while running git: {e.stderr}")

        sys.exit(1)

    except (KeyboardInterrupt, TypeError):

        print("\nOperation cancelled by user.")

        sys.exit(0)



def handle_commit(config, texts):

    """Handles the 'commit' command to create a semantic commit message."""

    try:

        # Check if there are any staged files

        result = subprocess.run(

            ['git', 'diff', '--cached', '--quiet'],

            capture_output=True,

            text=True

        )

        # If exit code is 0, there are no staged changes

        if result.returncode == 0:

            print(texts.get('no_files_to_commit', "Error: No files staged for commit."))

            return



        # Prepare choices for questionary

        lang = config.get("settings", {}).get("language", "en")

        commit_types = config.get('commit_types', [])

        choices = [

            questionary.Choice(

                title=item['names'].get(lang, item['names'].get('en', 'Unnamed Commit Type')),

                value=item['value']

            )

            for item in commit_types if 'names' in item

        ]



        # Ask for the commit type

        selected_type = questionary.select(

            texts.get('select_commit_type', "Select the commit type:"),

            choices=choices

        ).ask()



        if not selected_type:

            raise KeyboardInterrupt()



        # Ask for the commit message

        commit_message = questionary.text(

            texts.get('commit_message_prompt', "Enter the commit message:")

        ).ask()



        if not commit_message:

            raise KeyboardInterrupt()



        # Construct the final commit message and execute

        final_message = f"{selected_type}: {commit_message}"

        subprocess.run(['git', 'commit', '-m', final_message], check=True)

        print(f"\n{texts.get('commit_successful', 'Commit successful!')}")



    except FileNotFoundError:

        print("Error: 'git' command not found. Is Git installed and in your PATH?")

        sys.exit(1)

    except subprocess.CalledProcessError as e:

        print(f"An error occurred while running git: {e.stderr}")

        sys.exit(1)

    except (KeyboardInterrupt, TypeError):

        print("\nOperation cancelled by user.")

        sys.exit(0)



def handle_config(args, config, texts):

    """Handles the 'config' command to change settings."""

    if not args or len(args) < 2 or args[0] != '--lang':

        print("Usage: msc config --lang <en|pt>")

        return



    new_lang = args[1]



    # Validate if the new language is supported

    if new_lang not in config.get('texts', {}):

        print(f"Error: Language '{new_lang}' is not supported.")

        print("Supported languages are: " + ", ".join(config.get('texts', {}).keys()))

        return



    # Update the configuration file

    try:

        config['settings']['language'] = new_lang

        with open(CONFIG_FILE, 'w') as f:

            json.dump(config, f, indent=2)

        print(f"Language successfully changed to '{new_lang}'.")

    except Exception as e:

        print(f"An error occurred while writing to the config file: {e}")

        sys.exit(1)



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



        print("Error: Repository URL not configured.")



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



            # Fallback to manual update message if path isn't configured



            if not repo_path or not os.path.isdir(repo_path):



                print(texts.get('new_version_available', "New version available!").format(



                    remote_version=remote_version, 



                    repo_url=repo_url



                ))



                return







            # Attempt automatic update



            print(texts.get('attempting_auto_update', "Attempting automatic update..."))



            try:



                # Check for local changes before pulling



                status_result = subprocess.run(



                    ['git', '-C', repo_path, 'status', '--porcelain'],



                    capture_output=True, text=True, check=True



                )



                if status_result.stdout.strip():



                    print(texts.get('local_changes_detected', "Local changes detected. Please commit or stash them before updating."))



                    sys.exit(1)







                # Pull latest changes



                print(f"Running 'git pull' in '{repo_path}'...")



                subprocess.run(['git', '-C', repo_path, 'pull'], check=True, capture_output=True)







                # Re-run installer



                print("Re-running installer...")



                installer_path = os.path.join(repo_path, 'install.sh')



                # We need to run the installer from within the repo directory



                subprocess.run(['bash', installer_path], check=True, cwd=repo_path, capture_output=True)







                print(texts.get('update_complete', "Update complete!"))



                print(f"msc has been updated to version {remote_version}.")







            except Exception as e:



                print(texts.get('update_failed', "Automatic update failed. Please update manually."))



        else:



            print(texts.get('up_to_date', "You are already using the latest version."))







    except Exception as e:



        print(texts.get('update_check_failed', "Failed to check for updates."))



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

        handle_add(config, texts, args[1:])

    elif command == "commit":

        handle_commit(config, texts)

    elif command == "config":

        handle_config(args[1:], config, texts)

    elif command == "update":

        handle_update(config, texts)

    elif command == "--version" or command == "-v":

        handle_version(config)

    else:

        print(f"Error: Unknown command '{command}'")

        show_help(texts)

        sys.exit(1)



if __name__ == "__main__":

    main()
