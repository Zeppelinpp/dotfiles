return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    config = function(_, opts)
      require("persistence").setup(opts)

      -- Optimized auto-restore logic
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("auto_restore_session", { clear = true }),
        callback = function()
          -- Delay briefly to ensure other plugins (like Neo-tree) are initialized
          vim.schedule(function()
            local argc = vim.fn.argc()
            -- Case 1: nvim launched directly
            -- Case 2: nvim . launched
            -- Case 3: nvim with directory name
            if argc == 0 or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1) then
              -- Only restore when no non-empty file buffers are currently open
              -- This prevents accidental restore when manually opening a file like nvim test.py
              require("persistence").load()
            end
          end)
        end,
      })
    end,
  },
}
