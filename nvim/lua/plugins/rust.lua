return {
  -- 1. Configure crates.nvim (Cargo.toml dependency management)
  {
    "Saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    config = function()
      require("crates").setup({
        completion = {
          cmp = {
            enabled = false, -- 禁用 nvim-cmp 集成，使用 blink 的 LSP
          },
        },
      })
    end,
  },

  -- 2. Configure rustaceanvim
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = { "rust" },  -- 只在 Rust 文件类型时加载
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            diagnostics = {
              disabled = { "dead_code" },
            },
            completion = {
              autoimport = {
                enable = true,
              },
              callable = {
                snippets = "add_parentheses",
              },
              postfix = {
                enable = false,
              },
            },
            checkOnSave = false,
            cargo = {
              targetDir = true,
            },
            procMacro = {
              enable = true,
            },
            cachePriming = {
              enable = false,
            },
          },
        },
      },
    },
    config = function(_, opts)
      -- rustaceanvim 使用全局变量配置
      vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim or {}, opts)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function(event)
          vim.api.nvim_buf_create_user_command(event.buf, "LspRestart", function()
            vim.cmd.RustAnalyzer("restart")
          end, {
            nargs = "*",
            desc = "Restart rust-analyzer via rustaceanvim",
          })
        end,
      })
    end,
  },

  -- 3. Tell lspconfig not to manage rust_analyzer
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rust_analyzer = {
          enabled = false,
          mason = false,
        },
      },
    },
  },
}
