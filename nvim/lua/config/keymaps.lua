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
