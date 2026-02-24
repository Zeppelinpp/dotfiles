return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    config = function(_, opts)
      require("persistence").setup(opts)

      -- 优化后的自动恢复逻辑
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("auto_restore_session", { clear = true }),
        callback = function()
          -- 延时一小会儿确保其它插件（如 Neo-tree）初始化完成
          vim.schedule(function()
            local argc = vim.fn.argc()
            -- 情况 1: 直接输入 nvim
            -- 情况 2: 输入 nvim .
            -- 情况 3: 输入 nvim 目录名
            if argc == 0 or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1) then
              -- 只有当当前没有打开任何非空文件 buffer 时才恢复
              -- 这样可以防止如果你手动 nvim test.py 时误触发恢复
              require("persistence").load()
            end
          end)
        end,
      })
    end,
  },
}
