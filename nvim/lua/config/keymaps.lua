-- Save with Cmd-s (macOS)
vim.keymap.set({ "n", "i" }, "<D-s>", "<cmd>w<cr>", { desc = "Save File" })

vim.keymap.set("n", "<leader>fP", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied absolute path: " .. path)
end, { desc = "Copy Absolute Path" })

vim.keymap.set("n", "<leader>fp", function()
  local cwd = vim.fn.getcwd()
  local project_dir = vim.fn.fnamemodify(cwd, ":t")
  local relative_path = vim.fn.expand("%:.")

  local path = project_dir .. "/" .. relative_path

  vim.fn.setreg("+", path)
  vim.notify("Copied path from root: " .. path)
end, { desc = "Copy Path from Project Root" })

vim.keymap.set("n", "<leader>fn", function()
  local name = vim.fn.expand("%:t")
  vim.fn.setreg("+", name)
  vim.notify("Copied file name: " .. name)
end, { desc = "Copy File Name" })

-- Theme switching keymaps (<leader>u = UI)
vim.keymap.set("n", "<leader>uc", function()
  require("config.theme").switch("catppuccin")
end, { desc = "Colorscheme Catppuccin" })

vim.keymap.set("n", "<leader>um", function()
  require("config.theme").switch("monokai")
end, { desc = "Colorscheme Monokai Pro" })

vim.keymap.set("n", "<leader>ut", function()
  require("config.theme").toggle()
end, { desc = "Toggle Theme" })

vim.keymap.set("n", "<leader>uC", function()
  require("config.theme").picker()
end, { desc = "Choose Theme" })
