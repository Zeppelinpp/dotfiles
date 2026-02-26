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
fi
EOF
    fi
  } >> "$zsh_local"
}

ensure_claude_statusline_config() {
  local claude_dir="$HOME/.claude"
  local settings_file="$claude_dir/settings.json"
  local statusline_cmd="$HOME/Documents/cc-statusline/statusline.sh"

  mkdir -p "$claude_dir"

  if [[ -f "$statusline_cmd" ]]; then
    chmod +x "$statusline_cmd" 2>/dev/null || true
  else
    echo "  Warning: $statusline_cmd not found yet; statusLine will still be configured."
  fi

  if ! command_exists python3; then
    echo "  Warning: python3 not found, skipping Claude statusLine config update."
    return 0
  fi

  python3 - "$settings_file" "$statusline_cmd" <<'PY'
import json
import pathlib
import sys
from json import JSONDecodeError

settings_path = pathlib.Path(sys.argv[1])
statusline_cmd = sys.argv[2]

config = {}
if settings_path.exists():
    try:
        config = json.loads(settings_path.read_text(encoding="utf-8"))
        if not isinstance(config, dict):
            config = {}
    except JSONDecodeError:
        backup = settings_path.with_suffix(settings_path.suffix + ".bak")
        settings_path.rename(backup)
        config = {}

config["statusLine"] = {
    "type": "command",
    "command": statusline_cmd,
}

settings_path.write_text(
    json.dumps(config, indent=2, ensure_ascii=True) + "\n",
    encoding="utf-8",
)
PY
}

sync_cc_statusline_files() {
  local src_dir="$DOTFILES_DIR/cc-statusline"
  local dst_dir="$HOME/Documents/cc-statusline"

  if [[ ! -d "$src_dir" ]]; then
    echo "  Warning: $src_dir not found, skipping statusline file sync."
    return 0
  fi

  mkdir -p "$dst_dir"

  if [[ -f "$src_dir/ccr-statusline.ts" ]]; then
    cp "$src_dir/ccr-statusline.ts" "$dst_dir/ccr-statusline.ts"
  else
    echo "  Warning: $src_dir/ccr-statusline.ts not found."
  fi

  if [[ -f "$src_dir/statusline.sh" ]]; then
    cp "$src_dir/statusline.sh" "$dst_dir/statusline.sh"
    chmod +x "$dst_dir/statusline.sh" 2>/dev/null || true
  else
    echo "  Warning: $src_dir/statusline.sh not found."
  fi
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
else
  echo "==> Homebrew already installed"
fi

if ! setup_brew_shellenv; then
  echo "Failed to initialize Homebrew shellenv. Please check brew installation path."
  exit 1
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
  imagemagick
  luarocks
  nmap
  proxychains-ng
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
ensure_brew_in_zsh_local

mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.tmux.conf"    "$HOME/.tmux.conf"

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

# =====================
# 8. Sync Claude status line scripts
# =====================
echo "==> Syncing Claude status line scripts..."
sync_cc_statusline_files

# =====================
# 9. Configure Claude status line
# =====================
echo "==> Configuring Claude status line..."
ensure_claude_statusline_config

echo ""
echo "==> All done!"
echo "    1. Run 'exec zsh' to start your new shell"
echo "    2. Run 'nvim' to bootstrap LazyVim (plugins install automatically)"
