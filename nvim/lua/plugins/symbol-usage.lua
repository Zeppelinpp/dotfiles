return {
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = {
      vt_position = "end_of_line", -- Display at end of line, doesn't interfere with code layout, most hassle-free
      kinds = { 12, 6 }, -- 12 is function, 6 is method, only scan these two for best performance
    },
  },
}
