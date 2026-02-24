return {
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = {
      vt_position = "end_of_line", -- 显示在行尾，不干扰代码排版，最省心
      kinds = { 12, 6 }, -- 12是函数，6是方法，只扫描这两种，性能最高
    },
  },
}
