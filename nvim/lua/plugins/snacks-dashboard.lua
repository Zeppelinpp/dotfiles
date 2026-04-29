-- Advanced snacks.nvim dashboard configuration
-- Features multi-pane layout with header, keys, recent files, projects, and git status

return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      width = 60,
      row = nil,
      col = nil,
      pane_gap = 4,
      autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",

      -- Custom header (ASCII art)
      preset = {
        keys = {
          {
            icon = " ",
            key = "f",
            desc = "Find File",
            action = function()
              Snacks.picker.files()
            end,
          },
          {
            icon = " ",
            key = "n",
            desc = "New File",
            action = ":ene | startinsert",
          },
          {
            icon = " ",
            key = "g",
            desc = "Find Text",
            action = function()
              Snacks.picker.grep()
            end,
          },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files",
            action = function()
              Snacks.picker.recent()
            end,
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = function()
              Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
            end,
          },
          {
            icon = " ",
            key = "s",
            desc = "Restore Session",
            section = "session",
          },
          {
            icon = "󰒲 ",
            key = "L",
            desc = "Lazy",
            action = ":Lazy",
            enabled = package.loaded.lazy ~= nil,
          },
          {
            icon = " ",
            key = "q",
            desc = "Quit",
            action = ":qa",
          },
        },
        header = [[
    ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
    ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
    ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
        ]],
      },

      -- Advanced multi-pane layout
      sections = {
        -- Left pane: Header and key shortcuts
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },

        -- Right pane: Terminal decoration (colorful squares pattern)
        -- square-colorscript installed at ~/.local/bin/square-colorscript
        {
          pane = 2,
          section = "terminal",
          cmd = "~/.local/bin/square-colorscript 2>/dev/null || echo '    ♦ ♦ ♦ ♦ ♦ ♦'",
          height = 5,
          padding = 1,
        },

        -- Right pane: Recent files
        {
          pane = 2,
          icon = " ",
          title = "Recent Files",
          section = "recent_files",
          indent = 2,
          padding = 1,
          limit = 5,
        },

        -- Right pane: Projects
        {
          pane = 2,
          icon = " ",
          title = "Projects",
          section = "projects",
          indent = 2,
          padding = 1,
          limit = 5,
        },

        -- Right pane: Git status (only shown in git repo)
        {
          pane = 2,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = "git status --short --branch --renames 2>/dev/null || echo 'Not a git repository'",
          height = 5,
          padding = 1,
          ttl = 5 * 60, -- Cache for 5 minutes
          indent = 3,
        },

        -- Bottom: Startup time
        { section = "startup" },
      },

      -- Formats for different elements
      formats = {
        key = function(item)
          return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
        end,
      },
    },
  },
}
