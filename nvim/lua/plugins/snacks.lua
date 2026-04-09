return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            follow_file = true,
            transform = function(item)
              local path = item.file or ""
              local name = vim.fn.fnamemodify(path, ":t")

              item.name = name
              item.ext = item.dir and "" or vim.fn.fnamemodify(name, ":e")

              return item
            end,
            sort = {
              fields = { "dir:desc", "name" },
            },
            win = {
              list = {
                keys = {
                  ["<BS>"] = "explorer_up",
                  ["v"] = "edit_vsplit",
                  ["s"] = "edit_split",
                  ["t"] = "edit_tab",
                },
              },
            },
          },
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local dimmed_gray = "#5C594A"
          vim.api.nvim_set_hl(0, "SnacksPickerGitStatusIgnored", { fg = dimmed_gray, force = true })
          vim.api.nvim_set_hl(0, "SnacksPickerDimmed", { fg = dimmed_gray })
          vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { fg = dimmed_gray })
          vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { fg = dimmed_gray, force = true })
        end,
      })
    end,
  },
}
