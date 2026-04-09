---
name: sync-nvim
description: Sync local Neovim config (~/.config/nvim) into the dotfiles repository, stripping terminal-image display configs (image.nvim, magick, square-colorscript) and updating install.sh dependencies. Use when the user asks to sync nvim config to dotfiles, update dotfiles nvim from local machine, or mirror nvim configuration without terminal image support.
---

# Sync Nvim to Dotfiles

## Workflow

1. **Run the sync script** (preferred):
   ```bash
   python3 .claude/skills/sync-nvim/scripts/sync_nvim.py
   ```
2. **Review the diff** in `nvim/` and `install.sh`.
3. **Commit** when satisfied.

## What the Script Does

- `rsync`s `~/.config/nvim/` into the repo's `nvim/` directory
- Deletes `nvim/lua/plugins/image.lua`
- Removes `image = { enabled = true }` from `nvim/lua/plugins/snacks.lua`
- Removes the `square-colorscript` terminal decoration block from `nvim/lua/plugins/snacks-dashboard.lua`
- Removes hardcoded API key fallbacks from `nvim/lua/plugins/claudecode.lua`
- Purges local-only artifacts (`CLAUDE.md`, `claude`, `LICENSE`, `README.md`, `lua/plugins/example.lua`)
- Updates `install.sh`:
  - Removes `imagemagick` and `luarocks` from brew packages
  - Removes `cc-statusline` / `statusline` helper functions and their call sites

## Manual Fallback

If the script cannot be run:

1. `rsync -av --delete ~/.config/nvim/ ./nvim/`
2. Delete `nvim/lua/plugins/image.lua`
3. Strip `image = { enabled = true }` from `snacks.lua`
4. Strip the `square-colorscript` terminal block from `snacks-dashboard.lua`
5. Patch `install.sh` to remove image-related brew deps and statusline helpers
6. Remove local-only artifacts listed above
