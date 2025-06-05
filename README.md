# GitHub Commit Tracker

A lightweight tool that automatically tracks and logs all your Git commits across different repositories to a centralized private GitHub repository.

## What it does

This tool sets up a global Git post-commit hook that automatically:

- Captures commit details (hash, message, author, date, repository path)
- Logs them to a centralized `commits.log` file
- Pushes the log to a private GitHub repository called `commit-tracker`
- Works across all your Git repositories without manual intervention

## Prerequisites

- [GitHub CLI (gh)](https://cli.github.com/) installed and authenticated
- Git configured with your credentials
- Bash/Zsh shell

## Installation

1. Clone this repository:

```bash
git clone <this-repo-url>
cd ct-app
```

2. Run the installation script:

```bash
chmod +x install.sh
./install.sh
```

3. Reload your shell or run:

```bash
source ~/.zshrc  # or ~/.bashrc
```

## What the installer does

1. **Creates a private GitHub repository** called `commit-tracker`
2. **Clones it locally** to `~/.commit-tracker`
3. **Creates a tracking script** that captures commit information
4. **Sets up a global Git hook template** that runs after every commit
5. **Adds a `gclone` wrapper function** to automatically apply tracking to cloned repos

## Usage

### Automatic Tracking

Once installed, all commits in any Git repository will be automatically tracked. No additional action required!

### Manual Repository Setup

For existing repositories that don't have the hook, you can:

1. Use the `gclone` function instead of `git clone`:

```bash
gclone https://github.com/user/repo.git
```

2. Or manually copy the hook to existing repos:

```bash
cp ~/.git-templates/hooks/post-commit /path/to/your/repo/.git/hooks/
```

## How it works

1. **Post-commit hook**: Runs automatically after every `git commit`
2. **Data collection**: Captures commit hash, message, author, date, and repo path
3. **Centralized logging**: Appends to `~/.commit-tracker/commits.log`
4. **Auto-sync**: Pushes changes to your private GitHub repository

## Log format

Each commit is logged in the following format:

```
[2024-01-15 10:30:45 -0800] John Doe <john@example.com>: Fix bug in user authentication (a1b2c3d4) - Repo: /path/to/project
```

## Viewing your commit history

1. Visit your `commit-tracker` repository on GitHub
2. View the `commits.log` file to see all tracked commits
3. Or locally: `cat ~/.commit-tracker/commits.log`

## Files created

- `~/.commit-tracker/` - Local tracking repository
- `~/.commit-tracker/commits.log` - Central commit log
- `~/.git-templates/hooks/post-commit` - Global Git hook template
- Shell function `gclone` added to `~/.zshrc` and `~/.bashrc`

## Privacy

- The tracking repository is created as **private** by default
- Only you can see your commit history
- No sensitive code is logged, only commit metadata

## Troubleshooting

### Hook not working?

Check if the post-commit hook exists and is executable:

```bash
ls -la ~/.git-templates/hooks/post-commit
```

### Missing commits?

Ensure the tracking repository is accessible:

```bash
cd ~/.commit-tracker && git status
```

### GitHub CLI issues?

Verify authentication:

```bash
gh auth status
```

## Uninstall

To remove the commit tracker:

1. Remove the tracking repository:

```bash
rm -rf ~/.commit-tracker
gh repo delete commit-tracker
```

2. Remove global Git template:

```bash
git config --global --unset init.templateDir
rm -rf ~/.git-templates
```

3. Remove the `gclone` function from your shell config files

## License

MIT License - feel free to modify and distribute as needed.
