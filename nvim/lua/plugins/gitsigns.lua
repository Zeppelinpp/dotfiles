return {
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local original_on_attach = opts.on_attach
      opts.on_attach = function(buffer)
        local ft = vim.bo[buffer].filetype
        -- 跳过 snacks dashboard 和 picker，避免 blame 报错
        if ft == "snacks_dashboard" or ft == "snacks_picker_list" or ft == "snacks_picker_input" then
          return false
        end
        if original_on_attach then
          original_on_attach(buffer)
        end
      end
    end,
  },
}
