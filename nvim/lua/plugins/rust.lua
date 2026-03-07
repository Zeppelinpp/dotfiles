return {
  -- 1. 配置 rustaceanvim (LazyVim 官方推荐的 Rust 插件)
  {
    "mrcjkb/rustaceanvim",
    version = "^5", -- 确保使用较新版本
    lazy = false,
    opts = {
      server = {
        default_settings = {
          -- 这里就是原来的 rust-analyzer 配置区
          ["rust-analyzer"] = {
            -- 【保留你之前的配置】
            diagnostics = {
              disabled = { "dead_code" },
            },
            -- 【降温关键：关闭保存即检查】
            -- 这样不会每次 :w 都导致 CPU 飙升
            checkOnSave = false,
            -- 【降温关键：独立编译目录】
            -- 避免 RA 和你手动执行 cargo run 产生文件锁竞争
            cargo = {
              targetDir = true,
            },
            -- 【性能优化：限制宏展开的范围】
            procMacro = {
              enable = true,
            },
          },
        },
      },
    },
  },

  -- 2. 告诉 lspconfig 不要去管 rust_analyzer
  -- 这是为了防止 LazyVim 同时启动两个 LSP 导致冲突和双倍能耗
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        rust_analyzer = function()
          return true -- 返回 true 表示跳过 lspconfig 的设置
        end,
      },
    },
  },
}
