return {
  -- CUDA support using clangd
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        },
      },
    },
  },
  -- Ensure CUDA treesitter parser is installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "cuda" },
    },
  },
}
