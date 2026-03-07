-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Custom settings from previous config
vim.opt.clipboard = "unnamedplus"

-- OSC 52 clipboard for remote SSH sessions
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.spelllang = { "en", "cjk" }
vim.opt.spell = false
vim.env.EDITOR = "nvim"
