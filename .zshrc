# Zsh configuration {{{

export TERM=xterm-256color

setopt HIST_IGNORE_ALL_DUPS

bindkey -e

WORDCHARS=${WORDCHARS//[\/]}

# --------------------
# Module configuration
# --------------------

ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
source ${ZIM_HOME}/init.zsh
# }}}

# Starship
if (( ${+commands[starship]} )); then
  eval "$(starship init zsh)"
fi

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# PATH
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
[[ -d "$HOME/.bun/bin" ]] && export PATH="$HOME/.bun/bin:$PATH"

# Alias
alias gs="git status"
alias gac="git add . && git commit -m"
alias grm="git rm"
alias tns="tmux new -s"
alias tat="tmux attach -t"
alias tks="tmux kill-session -t"
alias dls="du -sh *(DN) 2>/dev/null | sort -hr"
alias lg="lazygit"
alias nv="nvim"
alias cc="claude --dangerously-skip-permissions"
alias reload="exec zsh"
alias pc='proxychains4 -q'
alias proxyon='export HTTP_PROXY=socks5h://127.0.0.1:1080 HTTPS_PROXY=socks5h://127.0.0.1:1080 ALL_PROXY=socks5h://127.0.0.1:1080 http_proxy=socks5h://127.0.0.1:1080 https_proxy=socks5h://127.0.0.1:1080 all_proxy=socks5h://127.0.0.1:1080; unset NO_PROXY no_proxy'
alias proxyoff='unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NO_PROXY no_proxy'
alias proxyoff='unset https_proxy http_proxy'
alias kimi="export ANTHROPIC_BASE_URL=https://api.kimi.com/coding/ ANTHROPIC_API_KEY=sk-kimi-kWeSxen5qsT6BhHsfgp1XhQfVmd7jq1KA4SrrQH4qZxpE54yJ2uCP7lh5yRdOBUY"
# alias claude="proxychains4 claude"

export PROXYCHAINS_QUIET_MODE=1
export PATH="$HOME/.cargo/bin:$PATH"

if (( ${+commands[eza]} )); then
  alias ls="eza --icons"
  alias lt="eza --tree --git --icons --group-directories-first"
  alias ll="eza -lh --git --icons --group-directories-first"
fi

# FZF
if (( ${+commands[fzf]} )); then
  export FZF_DEFAULT_COMMAND='fd --type f'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d'
  export FZF_CTRL_T_OPTS="
    --height 100% \
    --preview 'bat -n --color=always {}' \
    --preview-window 'right,60%,border-left' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' \
    --bind 'shift-up:preview-up,shift-down:preview-down'"
fi

frg() {
  INITIAL_QUERY="${*:-}"
  fzf --ansi --disabled --query "$INITIAL_QUERY" \
      --bind "start:reload(rg --column --line-number --no-heading --color=always --smart-case {q} || true)" \
      --bind "change:reload(rg --column --line-number --no-heading --color=always --smart-case {q} || true)" \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
      --preview-window 'right,60%,border-bottom,+{2}+3/3,~3' \
      --delimiter : \
      --bind 'enter:become(nvim {1} +{2})'
}

# Source local overrides (machine-specific config)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
export PATH="$HOME/.cargo/bin:$PATH"
