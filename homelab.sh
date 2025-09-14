#!/usr/bin/env bash
# setup.sh - Bootstrap Zsh environment and Homelab repo
set -euo pipefail

echo "🚀 Setting up system..."

# ------------------------------
# Detect package manager
# ------------------------------
if command -v apt-get >/dev/null; then
    PM="apt-get"
    UPDATE="apt-get update"
    INSTALL="apt-get install -y"
elif command -v dnf >/dev/null; then
    PM="dnf"
    UPDATE="dnf makecache"
    INSTALL="dnf install -y"
elif command -v pacman >/dev/null; then
    PM="pacman"
    UPDATE="pacman -Sy"
    INSTALL="pacman -S --noconfirm"
else
    echo "❌ No supported package manager found (apt, dnf, pacman)."
    exit 1
fi

# ------------------------------
# Install dependencies
# ------------------------------
echo "📦 Installing zsh, fzf, git, curl..."
sudo $UPDATE
sudo $INSTALL zsh fzf curl git

# ------------------------------
# Install oh-my-zsh if missing
# ------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "✨ Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ------------------------------
# Write ~/.zshrc
# ------------------------------
ZSHRC="$HOME/.zshrc"

cat > "$ZSHRC" <<'EOF'
# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="ys"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# fzf integration
if command -v fzf >/dev/null; then
  if fzf --zsh 2>/dev/null | grep -q 'bindkey'; then
    # Preferred method: eval the generated fzf bindings
    source <(fzf --zsh)
  elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    # Debian/Ubuntu path
    source /usr/share/doc/fzf/examples/key-bindings.zsh
    source /usr/share/doc/fzf/examples/completion.zsh
  elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
    # Arch/Fedora path
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
  fi
fi

# Expand aliases on space
function expand-alias() {
    zle _expand_alias
    zle self-insert
}
zle -N expand-alias
bindkey -M main ' ' expand-alias

# PATH adjustments
export PATH=$HOME/bin:/usr/local/bin:$PATH
EOF

# ------------------------------
# Make zsh default shell
# ------------------------------
if [ "$SHELL" != "$(command -v zsh)" ]; then
    echo "🔄 Changing default shell to zsh..."
    chsh -s "$(command -v zsh)"
fi

echo "✅ Zsh setup complete!"

# ------------------------------
# Homelab repo setup
# ------------------------------
REPO="git@github.com:danduta/homelab.git"
REPO_DIR="$HOME/homelab"
KEY="$HOME/.ssh/id_ed25519"

# 1. Generate SSH key if missing
if [ ! -f "$KEY" ]; then
    echo "🔑 No SSH key found, generating one..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$(hostname)@homelab" -f "$KEY" -N ""
    echo "✅ Key generated at $KEY"
    echo "⚠️ Add the following public key to GitHub:"
    cat "$KEY.pub"
    echo
    read -p "Press Enter after adding the key to GitHub..."
fi

# 2. Ensure GitHub host key is in known_hosts
if ! ssh-keygen -F github.com > /dev/null; then
    echo "🔒 Adding GitHub SSH host key to known_hosts..."
    ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
    chmod 600 "$HOME/.ssh/known_hosts"
fi

# 3. Clone repo if not already
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "📥 Cloning $REPO..."
    git clone "$REPO" "$REPO_DIR"
else
    echo "📂 Repo already exists at $REPO_DIR"
fi

cd "$REPO_DIR"

# 4. Ask to create a new stack
read -rp "Do you want to create a new stack? (y/n): " create
if [[ "$create" =~ ^[Yy]$ ]]; then
    read -rp "Enter new stack name: " stackname
    NEW_STACK="$REPO_DIR/$stackname"

    if [ -d "$NEW_STACK" ]; then
        echo "⚠️ Stack '$stackname' already exists!"
    else
        mkdir -p "$NEW_STACK/config"
        cat > "$NEW_STACK/docker-compose.yaml" <<EOF2
version: "3.9"
services:
  example:
    image: alpine
    command: echo "Hello from $stackname"
EOF2
        echo "✅ Created new stack at $NEW_STACK"

        git add "$stackname"
        git commit -m "Add new stack: $stackname"
        git push -u origin HEAD
        echo "📤 Auto-pushed new stack to GitHub."
    fi
fi

echo "🎉 All setup complete! Restart your shell with 'exec zsh'."
