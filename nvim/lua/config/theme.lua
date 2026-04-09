-- Theme management module
local M = {}

local theme_file = vim.fn.stdpath("cache") .. "/nvim_theme.txt"

-- Available themes
M.themes = {
  monokai = "monokai-pro",
  catppuccin = "catppuccin",
}

-- Load saved theme or return default
function M.load_theme()
  local file = io.open(theme_file, "r")
  if file then
    local theme = file:read("*l")
    file:close()
    if theme and vim.tbl_contains(vim.tbl_values(M.themes), theme) then
      return theme
    end
  end
  return M.themes.monokai -- default
end

-- Save theme preference
function M.save_theme(theme)
  local file = io.open(theme_file, "w")
  if file then
    file:write(theme)
    file:close()
  end
end

-- Switch theme with persistence
function M.switch(theme_name)
  local theme = M.themes[theme_name]
  if not theme then
    vim.notify("Unknown theme: " .. theme_name, vim.log.levels.ERROR)
    return
  end

  vim.cmd("colorscheme " .. theme)
  M.save_theme(theme)
  vim.notify("Theme: " .. theme_name .. " (" .. theme .. ")")
end

-- Toggle between themes
function M.toggle()
  local current = vim.g.colors_name
  if current == "catppuccin" then
    M.switch("monokai")
  else
    M.switch("catppuccin")
  end
end

-- Open theme picker with Telescope
function M.picker()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    -- Fallback to vim.ui.select if Telescope not available
    vim.ui.select(vim.tbl_keys(M.themes), {
      prompt = "Select Theme:",
    }, function(choice)
      if choice then
        M.switch(choice)
      end
    end)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local theme_list = {}
  for name, _ in pairs(M.themes) do
    table.insert(theme_list, name)
  end

  pickers.new({}, {
    prompt_title = "Select Colorscheme",
    finder = finders.new_table({
      results = theme_list,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        M.switch(selection[1])
      end)
      return true
    end,
  }):find()
end

return M
