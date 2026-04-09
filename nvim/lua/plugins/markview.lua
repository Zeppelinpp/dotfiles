return {
  "OXY2DEV/markview.nvim",
  ft = { "markdown", "md", "html", "latex", "tex", "typst", "asciidoc" },
  priority = 49,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    preview = {
      enable = true,
      icon_provider = "devicons",
      hybrid_modes = { "n" },
    },
  },
  config = function(_, opts)
    local markview = require("markview")
    markview.setup(opts)

    -- toggle render
    vim.keymap.set("n", "<leader>Mp", "<cmd>Markview toggle<cr>", {
      desc = "Toggle Markdown Preview",
      silent = true,
    })

    -- enable render
    vim.keymap.set("n", "<leader>Me", "<cmd>Markview enable<cr>", {
      desc = "Enable Markdown Preview",
      silent = true,
    })

    -- disable render
    vim.keymap.set("n", "<leader>Md", "<cmd>Markview disable<cr>", {
      desc = "Disable Markdown Preview",
      silent = true,
    })
  end,
}
