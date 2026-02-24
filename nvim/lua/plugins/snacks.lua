return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            -- 这里的设置会让 explorer 默认显示隐藏文件和被 git 忽略的文件
            hidden = true, -- 显示 .env, .gitignore 等
            ignored = true, -- 显示 .venv, node_modules 等被 git 忽略的目录
            follow_file = true, -- 自动定位到当前缓冲区文件
            win = {
              list = {
                keys = {
                  -- 如果你觉得 H 和 I 不好记，可以在这里自定义快捷键
                  ["<BS>"] = "explorer_up", -- 退回上级目录
                },
              },
            },
          },
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local dimmed_gray = "#5C594A"
          -- 1. 核心：处理被 Git 忽略的文件和文件夹（如 .git, .venv, node_modules）
          -- 如果觉得 #999999 还不够亮，可以改成 #CCCCCC
          vim.api.nvim_set_hl(0, "SnacksPickerGitStatusIgnored", { fg = dimmed_gray, force = true })

          -- 2. 关键：Snacks 经常用这个组来给不重要的项“降温”
          -- 调亮这个组通常能解决大部分“看不清”的问题
          vim.api.nvim_set_hl(0, "SnacksPickerDimmed", { fg = dimmed_gray })

          -- 3. 确保隐藏路径也清晰
          vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { fg = dimmed_gray })

          -- 4. 如果你希望 .git 文件夹的图标颜色也亮一点
          vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { fg = dimmed_gray, force = true })
        end,
      })
    end,
  },
}
