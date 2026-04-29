#!/usr/bin/env bash
set -euo pipefail

# --- Self-cloning for remote execution ---
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ ! -d "$DOTFILES_DIR/nvim" ]]; then
  echo "==> Dotfiles repo not found locally, cloning..."
  DOTFILES_DIR="$HOME/.dotfiles"
  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    git clone https://github.com/Zeppelinpp/dotfiles.git "$DOTFILES_DIR" || true
  fi
fi

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

setup_brew_shellenv() {
  local brew_bin=""

  if [[ "$PLATFORM" == "macos" ]]; then
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      brew_bin="/opt/homebrew/bin/brew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      brew_bin="/usr/local/bin/brew"
    fi
  else
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
      brew_bin="$HOME/.linuxbrew/bin/brew"
    fi
  fi

  if [[ -z "$brew_bin" ]]; then
    return 1
  fi

  eval "$("$brew_bin" shellenv)"
}

ensure_brew_in_zsh_local() {
  local zsh_local="$HOME/.zshrc.local"
  local marker="# Added by dotfiles install: Homebrew shellenv"

  if [[ -f "$zsh_local" ]] && grep -Fq "$marker" "$zsh_local"; then
    return 0
  fi

  {
    echo ""
    echo "$marker"
    if [[ "$PLATFORM" == "macos" ]]; then
      cat <<'EOF'
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
EOF
    else
      cat <<'EOF'
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi
EOF
    fi
  } >> "$zsh_local"
}

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

# ====================
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

# ====================
# 2. Install Homebrew / Linuxbrew
# =====================
if ! command_exists brew; then
  echo "==> Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "==> Homebrew already installed"
fi

if ! setup_brew_shellenv; then
  echo "Failed to initialize Homebrew shellenv. Please check brew installation path."
  exit 1
fi

# ====================
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
  nmap
  proxychains-ng
)
for pkg in "${BREW_PACKAGES[@]}"; do
  install_if_missing "$pkg" "$pkg"
done

# ====================
# 4. Symlink Zsh dotfiles
# =====================
echo "==> Linking Zsh dotfiles..."

link_file "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.zimrc"  "$HOME/.zimrc"
link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
ensure_brew_in_zsh_local

mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.tmux.conf"    "$HOME/.tmux.conf"

# ====================
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

# ====================
# 6. Symlink Neovim (LazyVim) config
# =====================
echo "==> Linking Neovim config..."

mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

echo "  lazy.nvim will auto-bootstrap on first nvim launch"

# ====================
# 7. Install local scripts
# =====================
echo "==> Installing local scripts..."

mkdir -p "$HOME/.local/bin"
if [[ -f "$DOTFILES_DIR/bin/square-colorscript" ]]; then
  cp "$DOTFILES_DIR/bin/square-colorscript" "$HOME/.local/bin/square-colorscript"
  chmod +x "$HOME/.local/bin/square-colorscript"
  echo "  square-colorscript -> ~/.local/bin/"
fi

# ====================
# 8. Set default shell to zsh
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
