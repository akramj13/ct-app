#!/bin/bash

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
touch commits.log
git add commits.log && git commit -m "Init log" && git push origin "$TRACKING_BRANCH"

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

# === 5. Add gclone wrapper to shell config ===
GCLONE_FUNC=$(cat << 'EOF'
function gclone() {
  git clone "$1" "$2"
  local target="${2:-$(basename "$1" .git)}"
  cp ~/.git-templates/hooks/post-commit "$target/.git/hooks/"
}
EOF
)

if ! grep -q "function gclone" ~/.zshrc 2>/dev/null; then
  echo "$GCLONE_FUNC" >> ~/.zshrc
fi

if ! grep -q "function gclone" ~/.bashrc 2>/dev/null; then
  echo "$GCLONE_FUNC" >> ~/.bashrc
fi

echo "[✓] gclone wrapper function added to shell config"

# === Done ===
echo -e "\n🎉 Setup complete!"
echo "- Use \`gclone <repo-url>\` to auto-apply commit tracking to clones."
echo "- All future \`git init\` repos will now track your contributions via post-commit hook."
