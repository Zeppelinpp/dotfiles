#!/usr/bin/env python3
"""Sync local ~/.config/nvim into the dotfiles repository, stripping terminal-image configs."""

import re
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
LOCAL_NVIM = HOME / ".config" / "nvim"
DOTFILES = Path(__file__).resolve().parents[4]
DOTFILES_NVIM = DOTFILES / "nvim"
INSTALL_SH = DOTFILES / "install.sh"


def run():
    if not LOCAL_NVIM.exists():
        print(f"ERROR: {LOCAL_NVIM} does not exist.", file=sys.stderr)
        sys.exit(1)

    DOTFILES_NVIM.mkdir(parents=True, exist_ok=True)

    # 1. rsync local nvim -> dotfiles/nvim
    # Exclude local artifacts that should not be in dotfiles
    excludes = [".gitignore", ".claude", "*.DS_Store", "CLAUDE.md", "claude", "LICENSE", "README.md", "lua/plugins/example.lua"]
    cmd = ["rsync", "-av", "--delete"] + [f"--exclude={e}" for e in excludes] + [f"{LOCAL_NVIM}/", f"{DOTFILES_NVIM}/"]
    subprocess.run(cmd, check=True)

    # 2. Remove terminal-image related plugin config
    image_lua = DOTFILES_NVIM / "lua" / "plugins" / "image.lua"
    if image_lua.exists():
        image_lua.unlink()
        print(f"Removed {image_lua}")

    # 3. Clean snacks.lua: remove image = { enabled = true }
    snacks_lua = DOTFILES_NVIM / "lua" / "plugins" / "snacks.lua"
    if snacks_lua.exists():
        content = snacks_lua.read_text(encoding="utf-8")
        content = re.sub(r",?\s*image\s*=\s*\{\s*enabled\s*=\s*true\s*\},?", "", content)
        snacks_lua.write_text(content, encoding="utf-8")
        print(f"Cleaned {snacks_lua}")

    # 4. Clean snacks-dashboard.lua: remove square-colorscript block
    dashboard_lua = DOTFILES_NVIM / "lua" / "plugins" / "snacks-dashboard.lua"
    if dashboard_lua.exists():
        content = dashboard_lua.read_text(encoding="utf-8")
        # Remove the terminal section with square-colorscript
        pattern = re.compile(
            r"\s*-- Right pane: Terminal decoration.*?"
            r"\{\s*pane\s*=\s*2,\s*section\s*=\s*\"terminal\",\s*"
            r"cmd\s*=\s*\"~/.local/bin/square-colorscript[^\"]*\",\s*"
            r"height\s*=\s*\d+,\s*padding\s*=\s*\d+,\s*\},",
            re.DOTALL,
        )
        content = pattern.sub("", content)
        # Also remove the preceding comment block if it exists
        content = re.sub(r"\n\n+", "\n\n", content)
        dashboard_lua.write_text(content, encoding="utf-8")
        print(f"Cleaned {dashboard_lua}")

    # 5. Clean claudecode.lua: remove hardcoded API key fallback
    claude_lua = DOTFILES_NVIM / "lua" / "plugins" / "claudecode.lua"
    if claude_lua.exists():
        content = claude_lua.read_text(encoding="utf-8")
        # Replace the else block with hardcoded key with trimmed version
        content = re.sub(
            r'(if kimi_key and kimi_key ~= "" then\s*\n'
            r'\s*vim\.env\.ANTHROPIC_API_KEY = kimi_key\s*\n'
            r'\s*vim\.env\.ANTHROPIC_BASE_URL = "https://api\.kimi\.com/coding/"\s*\n'
            r')\s*else.*?\n\s*end',
            r'\1      end',
            content,
            flags=re.DOTALL,
        )
        claude_lua.write_text(content, encoding="utf-8")
        print(f"Cleaned {claude_lua}")

    # 6. Post-sync: purge local artifacts that may have leaked
    for rel in ["CLAUDE.md", "claude", "LICENSE", "README.md", "lua/plugins/example.lua"]:
        artifact = DOTFILES_NVIM / rel
        if artifact.exists():
            artifact.unlink()
            print(f"Removed artifact {artifact}")

    # 7. Sync install.sh dependencies
    if INSTALL_SH.exists():
        content = INSTALL_SH.read_text(encoding="utf-8")
        original = content

        # Remove imagemagick and luarocks from brew list
        content = re.sub(r'\s+imagemagick\n', "\n", content)
        content = re.sub(r'\s+luarocks\n', "\n", content)

        # Remove cc-statusline / statusline helper functions
        content = re.sub(
            r'\nsync_cc_statusline_files\(\).*?\}\n',
            "\n",
            content,
            flags=re.DOTALL,
        )
        content = re.sub(
            r'\nensure_claude_statusline_config\(\).*?\}\n',
            "\n",
            content,
            flags=re.DOTALL,
        )

        # Remove calls to those functions
        content = re.sub(
            r'\n# =+\n# \d+\. Sync Claude status line scripts\n# =+\n.*?\n',
            "\n",
            content,
            flags=re.DOTALL,
        )
        content = re.sub(
            r'\n# =+\n# \d+\. Configure Claude status line\n# =+\n.*?\n',
            "\n",
            content,
            flags=re.DOTALL,
        )

        # Renumber remaining sections roughly
        content = re.sub(r'# =+\n# (\d+)\. ', lambda m: f'# {"="*20}\n# {m.group(1)}. ', content)

        if content != original:
            INSTALL_SH.write_text(content, encoding="utf-8")
            print(f"Updated {INSTALL_SH}")
        else:
            print(f"No changes needed for {INSTALL_SH}")

    print("Done.")


if __name__ == "__main__":
    run()
