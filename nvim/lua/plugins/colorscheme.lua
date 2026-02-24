return {
  -- Add Monokai Pro colorscheme
  {
    "loctvl842/monokai-pro.nvim",
    priority = 1000,
    config = function()
      require("monokai-pro").setup()
    end,
  },

  -- Configure LazyVim to use Monokai Pro
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai-pro",
    },
  },
}
