return {
  -- Monokai Pro (your default)
  {
    "loctvl842/monokai-pro.nvim",
    priority = 1000,
    config = function()
      require("monokai-pro").setup({
        transparent_background = false,
        terminal_colors = true,
        devicons = true,
        styles = {
          comment = { italic = true },
          keyword = { italic = true },
          type = { italic = true },
          storageclass = { italic = true },
          structure = { italic = true },
          parameter = { italic = true },
          annotation = { italic = true },
          tag_attribute = { italic = true },
        },
        filter = "pro", -- classic | octagon | pro | machine | ristretto | spectrum
        day_night = {
          enable = false,
          day_filter = "pro",
          night_filter = "pro",
        },
        inc_search = "background", -- underline | background
        background_clear = {
          "toggleterm",
          "telescope",
          "renamer",
          "notify",
        },
        plugins = {
          bufferline = {
            underline_selected = false,
            underline_visible = false,
            underline_fill = false,
            bold = true,
          },
          indent_blankline = {
            context_highlight = "default", -- default | pro
            context_start_underline = false,
          },
        },
        override = function(scheme)
          return {}
        end,
        override_palette = function(filter)
          return {}
        end,
        override_scheme = function(scheme, palette, colors)
          return {}
        end,
      })
    end,
  },

  -- Catppuccin (tmux-like theme)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "macchiato", -- matches your tmux: latte, frappe, macchiato, mocha
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      integrations = {
        telescope = true,
        notify = true,
        mini = true,
        which_key = true,
        indent_blankline = {
          enabled = true,
          colored_indent_levels = false,
        },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
        },
      },
    },
  },

  -- Set colorscheme based on saved preference
  {
    "LazyVim/LazyVim",
    opts = function()
      local theme = require("config.theme").load_theme()
      return {
        colorscheme = theme,
      }
    end,
  },
}
