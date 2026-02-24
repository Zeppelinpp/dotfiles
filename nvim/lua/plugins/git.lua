return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true, -- 开启当前行 commit 信息显示
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 信息显示在行尾。可选 'overlay', 'right_align'
        delay = 500, -- 光标停顿多久后显示 (毫秒)
        ignore_whitespace = false,
      },
      current_line_blame_formatter = " <author>, <author_time:%Y-%m-%d> - <summary>",
    },
  },
}
