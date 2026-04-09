return {
  {
    "hrsh7th/nvim-cmp",
    enabled = false,
  },
  {
    "folke/noice.nvim",
    opts = {
      popupmenu = {
        enabled = false,
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = {
        preset = "none",
        ["<Tab>"] = { "accept", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Esc>"] = { "cancel", "fallback" },
      }

      opts.sources = opts.sources or {}
      -- 覆盖 LazyVim 默认 source，避免 snippets/buffer 把无关建议混进来
      opts.sources.default = { "lsp", "path" }
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        lsp = {
          name = "LSP",
          score_offset = 1000,
        },
        path = {
          name = "Path",
          score_offset = 500,
        },
      })
    end,
  },
}
