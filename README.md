<div align="center">

```
███╗   ███╗   ██████╗    ██████╗
████╗ ████║  ██╔════╝   ██╔════╝
██╔████╔██║  ╚█████╗    ██║
██║╚██╔╝██║   ╚═══██╗   ██║
██║ ╚═╝ ██║  ██████╔╝   ██╚════╝
╚═╝     ╚═╝  ╚═════╝    ╚██████╝
```

</div>

<h1 align="center">MSC - My Semantic Commit</h1>

<p align="center">
  A command-line tool designed to streamline your Git workflow by making it easy to create semantic, conventional commits with emojis.
</p>

---

## ✨ Key Features

-   **Interactive Commit Creation**: Guides you through selecting a commit type and writing your message.
-   **Customizable Commit Types**: Don't like the defaults? Add, edit, remove, or reset commit types (flags and emojis) through an easy-to-use interactive menu.
-   **Smart File Staging**: An interactive `msc add` command lets you choose which modified, new, or deleted files to stage.
-   **Safe Push**: Includes a confirmation step before pushing to `main` or `master` branches.
-   **Self-Updating**: Stay up-to-date with a simple `msc update` command.
-   **Multi-Language Support**: Available in English and Portuguese.

## 🚀 Installation

You can install MSC by cloning this repository and running the installer script.

```bash
# 1. Clone the repository
git clone https://github.com/mockqv/msc.git

# 2. Navigate into the directory
cd msc

# 3. Run the installer
bash install.sh
```

The installer will add the `msc` command to your system path, making it available globally. It will also ask for your preferred language and create a local configuration file at `~/.config/msc/config.json`.

##  usage

MSC is designed to be simple and intuitive. Here are the main commands:

| Command                 | Description                                                              |
| ----------------------- | ------------------------------------------------------------------------ |
| `msc add [files...]`    | Interactively select files to stage, or stage them directly.             |
| `msc commit`            | Start the interactive process to create a semantic commit message.       |
| `msc push`              | Push your commits to the remote repository (with a safety check).        |
| `msc config`            | Open the interactive configuration menu to customize the tool.           |
| `msc update`            | Check for and install updates to MSC.                                    |
| `msc --version` / `-v`  | Show the current version of the tool.                                    |
| `msc --help`            | Show the help message.                                                   |

### Example Workflow

```bash
# Interactively add files to staging
$ msc add

# Create a semantic commit
$ msc commit
? Select the commit type: › ✨ feat: A new feature
? Enter the commit message: › implement user authentication

# Push your changes
$ msc push
```

## 🔧 Configuration & Customization

MSC is highly customizable via the interactive configuration menu. Simply run:

```bash
msc config
```

This menu allows you to:
-   **Change Language**: Switch between English and Portuguese.
-   **Edit Commit Types**:
    -   **Add**: Create a new commit type with your own emoji and flag.
    -   **Edit**: Modify an existing commit type.
    -   **Remove**: Delete a commit type you no longer need.
    -   **Reset**: Restore the commit types to the initial default list.

Your personal customizations are saved in `~/.config/msc/config.json` and are preserved even when you update the tool.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.