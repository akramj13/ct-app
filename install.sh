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

git pull --no-rebase origin "$TRACKING_BRANCH" || echo "⚠️ Warning: git pull failed (may be initial run)"

if [ -n "$(git status --porcelain commits.log)" ]; then
  echo "[*] Committing commits.log..."
  git add commits.log
  git commit -m "Init log" || echo "⚠️ Nothing to commit"
  git push origin "$TRACKING_BRANCH" --force || echo "⚠️ Push failed, please check auth"
else
  echo "[✓] commits.log already up to date"
fi

# === 3. Create the tracking script ===
mkdir -p "$SCRIPTS_PATH"

cat << 'EOF' > "$SCRIPT_FILE"
#!/bin/bash
set -e

TRACKING_REPO_PATH="$HOME/.commit-tracker"
TRACKING_BRANCH="main"
WORKING_REPO_PATH=$(pwd)

# 🛑 Prevent infinite recursion (when committing inside tracking repo)
if [ "$WORKING_REPO_PATH" = "$TRACKING_REPO_PATH" ]; then
  exit 0
fi

COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MESSAGE=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty="%an <%ae>")
COMMIT_DATE=$(git log -1 --pretty=%ci)

echo "[$COMMIT_DATE] $COMMIT_AUTHOR: $COMMIT_MESSAGE ($COMMIT_HASH) - Repo: $WORKING_REPO_PATH" >> "$TRACKING_REPO_PATH/commits.log"

cd "$TRACKING_REPO_PATH"

git pull --no-rebase origin "$TRACKING_BRANCH" || echo "⚠️ Git pull failed"

git add commits.log

# 🚫 Disable hooks for this commit to avoid recursion
git -c core.hooksPath=/dev/null commit -m "Logged commit: $COMMIT_HASH" || echo "⚠️ Nothing new to commit"

# 🚫 Removed --force for safety
git push origin "$TRACKING_BRANCH" || echo "⚠️ Git push failed"
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
echo "[✓] Hook template created at $HOOKS_TEMPLATE_DIR/post-commit"

# === Done ===
echo -e "\n🎉 \033[1;32mSetup complete!\033[0m"
echo "- All future \`git init\` repos that use this template will have the commit tracker hook."
echo "- For existing repos, manually copy the hook:"
echo "    cp ~/.git-templates/hooks/post-commit .git/hooks/ && chmod +x .git/hooks/post-commit"