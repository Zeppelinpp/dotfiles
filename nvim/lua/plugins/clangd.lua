return {
  -- Configure clangd for C/C++/CUDA
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          filetypes = { "c", "cpp", "cuda", "objc", "objcpp" },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=bundled",
            "--pch-storage=memory",
            "--cross-file-rename",
          },
        },
      },
    },
  },
}
