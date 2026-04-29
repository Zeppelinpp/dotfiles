[[ $- != *i* ]] && return
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# Start configuration added by Zim Framework install {{{
#
# User configuration sourced by interactive shells
#
# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh
# }}} End configuration added by Zim Framework install

# Starship Theme - must be loaded after Zim
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
# export PATH="/Users/ruipu/miniconda3/bin:$PATH"  # commented out by conda initialize

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/ruipu/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/ruipu/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/ruipu/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/ruipu/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Rust / Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export PATH="/usr/local/share/dotnet/sdk:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# Alias
alias cl="clear"
alias gs="git status"
alias gac="git add . && git commit -m"
alias grm="git rm"
alias tns="tmux new -s"
alias tat="tmux attach -t"
alias tks="tmux kill-session -t"
alias dls="du -sh *(DN) 2>/dev/null | sort -hr"
alias typora="open -a typora"
alias lg="lazygit"
alias nv="nvim"
alias cc="claude --dangerously-skip-permissions"
alias ls="eza --icons --group-directories-first"
alias lt="eza --tree --git --icons --group-directories-first"
alias ll="eza -lh --git --icons --group-directories-first"
alias kimi="export ANTHROPIC_BASE_URL=https://api.kimi.com/coding/ ANTHROPIC_API_KEY=sk-kimi-kWeSxen5qsT6BhHsfgp1XhQfVmd7jq1KA4SrrQH4qZxpE54yJ2uCP7lh5yRdOBUY"
# alias claude="proxychains4 claude"


# FD
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

# bun completions
[ -s "/Users/ruipu/.bun/_bun" ] && source "/Users/ruipu/.bun/_bun"


# claude code-openrouter
# export OPENROUTER_API_KEY="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"
# export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
# export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
# export ANTHROPIC_API_KEY=""

# claude code-dashscope
# export ANTHROPIC_BASE_URL=https://dashscope-intl.aliyuncs.com/apps/anthropic
# export ANTHROPIC_API_KEY=sk-88551cce573d49fe81aa466d78c21741 # Replace YOUR_DASHSCOPE_API_KEY with your Model Studio API key
# export ANTHROPIC_MODEL=qwen3-max-2026-01-23 # Replace with another supported model as needed.

# OpenClaw Completion
[[ -f "/Users/ruipu/.openclaw/completions/openclaw.zsh" ]] && source "/Users/ruipu/.openclaw/completions/openclaw.zsh"
