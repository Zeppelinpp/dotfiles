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

# --- Install zsh (Linux only) ---
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

# --- Install Homebrew / Linuxbrew ---
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

# --- Install core packages ---
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

# --- Symlink dotfiles ---
echo "==> Linking dotfiles..."

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

link_file "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.zimrc"  "$HOME/.zimrc"
link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"

mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# --- Install Zim framework ---
if [[ ! -d "$HOME/.zim" ]]; then
  echo "==> Installing Zim framework..."
  curl -fsSL --create-dirs -o "$HOME/.zim/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  zsh -c "source $HOME/.zim/zimfw.zsh init && source $HOME/.zim/zimfw.zsh install"
else
  echo "==> Zim already installed, updating modules..."
  zsh -c "source $HOME/.zim/zimfw.zsh install"
fi

# --- Set default shell to zsh ---
ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  echo "==> Setting zsh as default shell..."
  if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi
  sudo chsh -s "$ZSH_PATH" "$(whoami)" 2>/dev/null || chsh -s "$ZSH_PATH" 2>/dev/null || true
fi

echo ""
echo "==> Done! Run 'exec zsh' to start your new shell."
