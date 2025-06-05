#!/bin/bash
set -e  # Exit on error

# === Configuration ===
TRACKING_REPO_NAME="commit-tracker"
TRACKING_REPO_PATH="$HOME/.commit-tracker"
SCRIPTS_PATH="$TRACKING_REPO_PATH/scripts"
TRACKING_BRANCH="main"
HOOKS_TEMPLATE_DIR="$HOME/.git-templates/hooks"
SCRIPT_FILE="$SCRIPTS_PATH/track-commit.sh"

echo "🔧 Starting GitHub Commit Tracker setup..."

# === 1. Create Repo with GitHub CLI ===
if ! gh repo list | grep -q "$TRACKING_REPO_NAME"; then
  echo "[*] Creating GitHub repo: $TRACKING_REPO_NAME..."
  gh repo create "$TRACKING_REPO_NAME" --private --confirm
else
  echo "[✓] GitHub repo already exists"
fi

# === 2. Clone to ~/.commit-tracker ===
if [ ! -d "$TRACKING_REPO_PATH" ]; then
  echo "[*] Cloning tracking repo to $TRACKING_REPO_PATH..."
  gh repo clone "$TRACKING_REPO_NAME" "$TRACKING_REPO_PATH"
else
  echo "[✓] Local clone already exists at $TRACKING_REPO_PATH"
fi

cd "$TRACKING_REPO_PATH"

# Ensure commits.log exists and is committed
touch commits.log
if [ -z "$(git status --porcelain commits.log)" ]; then
  echo "[✓] commits.log already committed"
else
  git add commits.log
  git commit -m "Init log"
  git push origin "$TRACKING_BRANCH"
fi

# === 3. Create the tracking script ===
mkdir -p "$SCRIPTS_PATH"

cat << 'EOF' > "$SCRIPT_FILE"
#!/bin/bash
TRACKING_REPO_PATH="$HOME/.commit-tracker"
TRACKING_BRANCH="main"
WORKING_REPO_PATH=$(pwd)
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MESSAGE=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty="%an <%ae>")
COMMIT_DATE=$(git log -1 --pretty=%ci)
echo "[$COMMIT_DATE] $COMMIT_AUTHOR: $COMMIT_MESSAGE ($COMMIT_HASH) - Repo: $WORKING_REPO_PATH" >> "$TRACKING_REPO_PATH/commits.log"
cd "$TRACKING_REPO_PATH"
git pull origin "$TRACKING_BRANCH" > /dev/null 2>&1
git add commits.log
git commit -m "Logged commit: $COMMIT_HASH" > /dev/null 2>&1
git push origin "$TRACKING_BRANCH" > /dev/null 2>&1
EOF

chmod +x "$SCRIPT_FILE"
echo "[✓] Commit tracker script created at $SCRIPT_FILE"

# === 4. Set Up Global Git Hook Template ===
mkdir -p "$HOOKS_TEMPLATE_DIR"

cat << EOF > "$HOOKS_TEMPLATE_DIR/post-commit"
#!/bin/bash
$SCRIPT_FILE
EOF

chmod +x "$HOOKS_TEMPLATE_DIR/post-commit"
git config --global init.templateDir "$HOME/.git-templates"
echo "[✓] Global post-commit hook configured"

# === Done ===
echo -e "\n🎉 \033[1;32mSetup complete!\033[0m"
echo "- All future \`git init\` repos will now track your contributions via post-commit hook."
echo "- For existing repos, manually copy the hook:"
echo "    cp ~/.git-templates/hooks/post-commit .git/hooks/ && chmod +x .git/hooks/post-commit"
