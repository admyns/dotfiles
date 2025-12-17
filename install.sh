#!/usr/bin/env bash
set -e

DOTFILES="$HOME/Projects/Dotfiles"
BACKUP_DIR="$HOME/Projects/Dotfiles_backup"

echo "🔗 Installing dotfiles..."
mkdir -p "$BACKUP_DIR"

# Detect OS
OS="$(uname -s)"
echo "Detected OS: $OS"

if [[ "$OS" == "Darwin" ]]; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
    CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
elif [[ "$OS" == "Linux" ]]; then
    VSCODE_DIR="$HOME/.config/Code/User"
    CURSOR_DIR="$HOME/.config/Cursor/User"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

mkdir -p "$VSCODE_DIR" "$CURSOR_DIR"

# Function to backup and symlink
link() {
    TARGET=$1
    LINK_NAME=$2

    if [ -e "$LINK_NAME" ] || [ -L "$LINK_NAME" ]; then
        echo "📦 Backing up existing $(basename $LINK_NAME)"
        mv "$LINK_NAME" "$BACKUP_DIR/$(basename $LINK_NAME).backup"
    fi

    ln -sf "$TARGET" "$LINK_NAME"
    echo "Linked $(basename $LINK_NAME)"
}

# -----------------
# Dotfiles Symlinks
# -----------------
link "$DOTFILES/vim/vimrc" "$HOME/.vimrc"
mkdir -p "$HOME/.config/ghostty"
link "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
link "$DOTFILES/vscode/settings.json" "$VSCODE_DIR/settings.json"
link "$DOTFILES/vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"
link "$DOTFILES/cursor/settings.json" "$CURSOR_DIR/settings.json"
link "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
link "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"

# -----------------
# Homebrew
# -----------------
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$OS" == "Linux" ]]; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

echo "Installing Brew packages..."
brew bundle --file="$DOTFILES/brew/Brewfile"

# -----------------
# Zsh as default shell
# -----------------
if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔧 Changing default shell to Zsh..."
    chsh -s "$(which zsh)" || echo "⚠️ Could not change default shell, please run manually."
fi

# -----------------
# Oh My Posh
# -----------------
if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "✨ Installing Oh My Posh..."
    brew install jandedobbeleer/oh-my-posh/oh-my-posh
fi

# Oh My Posh theme symlink
mkdir -p "$HOME/.poshthemes"
link "$DOTFILES/oh-my-posh/theme.omp.json" "$HOME/.oh-my-posh/theme.omp.json"

echo "🎉 All dotfiles installed successfully!"
echo "➡️ Restart your terminal to see Zsh + Oh My Posh in action."
