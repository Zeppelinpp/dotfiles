#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- OS detection ---
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac
echo "==> Detected platform: $PLATFORM"

# --- Helper ---
command_exists() { command -v "$1" &>/dev/null; }

install_if_missing() {
  local cmd="$1"
  local pkg="${2:-$1}"
  if ! command_exists "$cmd"; then
    echo "  Installing $pkg..."
    brew install "$pkg"
  else
    echo "  $cmd already installed, skipping"
  fi
}

link_file() {
  local src="$1"
  local dst="$2"
  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="${dst}.bak.$(date +%s)"
    echo "  Backing up existing $dst -> $backup"
    mv "$dst" "$backup"
  fi
  ln -sf "$src" "$dst"
  echo "  $src -> $dst"
}

# =====================
# 1. Install zsh (Linux only)
# =====================
if [[ "$PLATFORM" == "linux" ]] && ! command_exists zsh; then
  echo "==> Installing zsh..."
  if command_exists apt-get; then
    sudo apt-get update && sudo apt-get install -y zsh
  elif command_exists yum; then
    sudo yum install -y zsh
  elif command_exists pacman; then
    sudo pacman -S --noconfirm zsh
  else
    echo "Cannot detect package manager, please install zsh manually"
    exit 1
  fi
fi

# =====================
# 2. Install Homebrew / Linuxbrew
# =====================
if ! command_exists brew; then
  echo "==> Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "$PLATFORM" == "macos" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
else
  echo "==> Homebrew already installed"
fi

# =====================
# 3. Install core packages
# =====================
echo "==> Installing packages via brew..."
BREW_PACKAGES=(
  eza
  bat
  fd
  fzf
  ripgrep
  lazygit
  neovim
  tmux
  starship
  git
)
for pkg in "${BREW_PACKAGES[@]}"; do
  install_if_missing "$pkg" "$pkg"
done

# =====================
# 4. Symlink Zsh dotfiles
# =====================
echo "==> Linking Zsh dotfiles..."

link_file "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.zimrc"  "$HOME/.zimrc"
link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"

mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# =====================
# 5. Install Zim framework
# =====================
ZIM_HOME="$HOME/.zim"
if [[ ! -d "$ZIM_HOME" ]]; then
  echo "==> Installing Zim framework..."
  curl -fsSL --create-dirs -o "$ZIM_HOME/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  zsh -c "ZIM_HOME=$ZIM_HOME source $ZIM_HOME/zimfw.zsh init && source $ZIM_HOME/zimfw.zsh install"
else
  echo "==> Zim already installed, updating modules..."
  zsh -c "ZIM_HOME=$ZIM_HOME source $ZIM_HOME/zimfw.zsh install"
fi

# =====================
# 6. Symlink Neovim (LazyVim) config
# =====================
echo "==> Linking Neovim config..."

mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

echo "  lazy.nvim will auto-bootstrap on first nvim launch"

# =====================
# 7. Set default shell to zsh
# =====================
ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  echo "==> Setting zsh as default shell..."
  if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi
  sudo chsh -s "$ZSH_PATH" "$(whoami)" 2>/dev/null || chsh -s "$ZSH_PATH" 2>/dev/null || true
fi

echo ""
echo "==> All done!"
echo "    1. Run 'exec zsh' to start your new shell"
echo "    2. Run 'nvim' to bootstrap LazyVim (plugins install automatically)"
