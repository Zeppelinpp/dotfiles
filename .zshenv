# Skip system-wide compinit (prevents Zim warning on Debian/Ubuntu/Docker)
skip_global_compinit=1

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
