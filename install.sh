#!/usr/bin/env bash
set -e

# Resolve the dotfiles dir from this script's own location, so the repo can be
# cloned anywhere (not just ~/Dotfiles).
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/Dotfiles-backup"

echo "🔗 Installing dotfiles..."
mkdir -p "$BACKUP_DIR"

# Detect OS
OS="$(uname -s)"
echo "💻 Detected OS: $OS"

if [[ "$OS" == "Darwin" ]]; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
    CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
elif [[ "$OS" == "Linux" ]]; then
    VSCODE_DIR="$HOME/.config/Code/User"
    CURSOR_DIR="$HOME/.config/Cursor/User"
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

mkdir -p "$VSCODE_DIR" "$CURSOR_DIR"

# -----------------
# Helper function: backup + symlink
# -----------------
link() {
    local TARGET="$1"
    local LINK_NAME="$2"
    
    # Create a relative backup path structure
    local RELATIVE_PATH="${LINK_NAME#"$HOME/"}"
    
    # Remove leading dot from path to make it visible in Finder
    local VISIBLE_PATH="${RELATIVE_PATH#.}"
    VISIBLE_PATH="${VISIBLE_PATH#/}"  # Remove leading slash if any
    
    local BACKUP_PATH="$BACKUP_DIR/$(dirname "$VISIBLE_PATH")"
    local BACKUP_FILE="$BACKUP_PATH/$(basename "$LINK_NAME").backup"
    
    if [ -e "$LINK_NAME" ] || [ -L "$LINK_NAME" ]; then
        mkdir -p "$BACKUP_PATH"
        mv "$LINK_NAME" "$BACKUP_FILE"
        echo "📦 Backed up to: $BACKUP_FILE"
    else
        echo "⏭️ No existing file to backup: $(basename "$LINK_NAME")"
    fi
    
    ln -sf "$TARGET" "$LINK_NAME"
    echo "✅ Linked $(basename "$LINK_NAME")"
}

# -----------------
# Symlink Dotfiles
# -----------------
link "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"

link "$DOTFILES/vim/vimrc" "$HOME/.vimrc"

mkdir -p "$HOME/.oh-my-posh"
link "$DOTFILES/oh-my-posh/theme.omp.json" "$HOME/.oh-my-posh/theme.omp.json"

mkdir -p "$HOME/.config/ghostty"
link "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"

link "$DOTFILES/vscode/settings.json" "$VSCODE_DIR/settings.json"
link "$DOTFILES/vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"

link "$DOTFILES/cursor/settings.json" "$CURSOR_DIR/settings.json"
link "$DOTFILES/cursor/keybindings.json" "$CURSOR_DIR/keybindings.json"

# -----------------
# Zsh as default shell
# -----------------
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔧 Changing default shell to Zsh..."
    chsh -s "$(which zsh)" || echo "⚠️ Could not change default shell, please run manually."
fi

# -----------------
# Homebrew
# -----------------
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for the rest of this script (the installer does not
# modify the current shell's environment).
if ! command -v brew >/dev/null 2>&1; then
    if [[ "$OS" == "Darwin" ]]; then
        # Apple Silicon installs to /opt/homebrew, Intel to /usr/local
        for BREW_BIN in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            if [ -x "$BREW_BIN" ]; then
                echo "eval \"\$($BREW_BIN shellenv)\"" >> "$HOME/.zprofile"
                eval "$("$BREW_BIN" shellenv)"
                break
            fi
        done
    elif [[ "$OS" == "Linux" ]]; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew installation failed or brew is not on PATH. Please install manually and re-run."
    exit 1
fi

echo "Installing Brew packages..."
brew bundle --file="$DOTFILES/brew/Brewfile"

# -----------------
# Oh My Posh Installation
# -----------------
if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "✨ Installing Oh My Posh..."
    brew install jandedobbeleer/oh-my-posh/oh-my-posh
fi

# -----------------
# Load theme in zshrc
# -----------------
if ! grep -q "oh-my-posh init zsh" "$HOME/.zshrc"; then
    echo 'eval "$(oh-my-posh init zsh --config $HOME/.oh-my-posh/theme.omp.json)"' >> "$HOME/.zshrc"
    echo "✨ Added Oh My Posh theme loading to zshrc"
fi

echo "🎉 All dotfiles installed successfully!"
echo "➡️ Restart your terminal to see Zsh + Oh My Posh with your theme."
