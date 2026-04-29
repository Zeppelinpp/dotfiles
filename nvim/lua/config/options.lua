-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_cmp = "blink.cmp"

-- Custom settings from previous config
vim.opt.timeoutlen = 800 -- 增加 leader 键等待时间（毫秒）
vim.opt.autoread = true
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.spelllang = { "en", "cjk" }
vim.opt.spell = false
vim.env.EDITOR = "nvim"
