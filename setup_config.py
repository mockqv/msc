import json
import os
import shutil
import questionary
from collections.abc import MutableMapping

def deep_update(d, u):
    """
    Recursively update a dictionary 'd' with values from 'u'.
    If a key in 'u' is a dictionary, it recursively updates the corresponding key in 'd'.
    Otherwise, it just sets the value.
    """
    for k, v in u.items():
        if isinstance(v, MutableMapping):
            d[k] = deep_update(d.get(k, {}), v)
        else:
            d[k] = v
    return d

# --- Configuration ---
if os.name == 'nt':
    # Windows: Use %APPDATA%
    CONFIG_DIR = os.path.join(os.getenv('APPDATA'), 'msc')
else:
    # Linux/macOS: Use ~/.config
    CONFIG_DIR = os.path.join(os.path.expanduser('~'), '.config', 'msc')

USER_CONFIG_FILE = os.path.join(CONFIG_DIR, 'config.json')
REPO_CONFIG_FILE = 'config.json'

os.makedirs(CONFIG_DIR, exist_ok=True)

try:
    # Use utf-8 encoding for cross-platform compatibility
    with open(REPO_CONFIG_FILE, 'r', encoding='utf-8') as f:
        repo_config = json.load(f)
    
    lang = repo_config.get('settings', {}).get('language', 'en')
    texts = repo_config.get('texts', {}).get(lang, repo_config.get('texts', {}).get('en', {}))

    if os.path.exists(USER_CONFIG_FILE):
        # --- Merge existing config ---
        print(texts.get('installer_config_merged', 'Existing configuration found. Merging new settings.'))
        with open(USER_CONFIG_FILE, 'r', encoding='utf-8') as f:
            user_config = json.load(f)

        # Preserve user's custom settings and commit types
        repo_config['settings'] = user_config.get('settings', repo_config['settings'])
        repo_config['commit_types'] = user_config.get('commit_types', repo_config['commit_types'])
        
        # Deep update texts to add new translations without overwriting user changes
        merged_texts = deep_update(repo_config['texts'], user_config.get('texts', {}))
        repo_config['texts'] = merged_texts

        # Update repository path from environment variable
        repo_config['repository_path'] = os.environ.get('MSC_REPO_PATH', '')

        # Write the merged config back
        with open(USER_CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(repo_config, f, indent=2)
        print(texts.get('installer_config_updated', 'Configuration file updated.'))

    else:
        # --- First-time setup ---
        shutil.copy(REPO_CONFIG_FILE, USER_CONFIG_FILE)
        
        lang_map = {'🇺🇸 English': 'en', '🇧🇷 Português': 'pt'}
        prompt_text = texts.get('installer_language_prompt', 'Please choose your language:')
        
        selected_lang = 'en'
        try:
            if os.name == 'nt':
                # Simple input for Windows batch context
                choice = input(f'{prompt_text} (en/pt): ').lower()
                selected_lang = 'pt' if choice == 'pt' else 'en'
            else:
                # questionary for Linux/macOS
                choice = questionary.select(
                    prompt_text,
                    choices=list(lang_map.keys())
                ).ask()
                if choice:
                    selected_lang = lang_map.get(choice, 'en')

        except (KeyboardInterrupt, EOFError):
             print('\nLanguage selection cancelled. Defaulting to English.')
             selected_lang = 'en'


        print(texts.get('installer_language_set', 'Language set to \'{lang}\'.').format(lang=selected_lang))

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
