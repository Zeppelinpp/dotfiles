return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python",
      "linux-cultist/venv-selector.nvim",
    },
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({})

      require("dap-python").setup("python")

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "file",
          program = "${file}",
          cwd = "${workspaceFolder}",
        },
        {
          type = "python",
          request = "launch",
          name = "file with args",
          program = "${file}",
          cwd = "${workspaceFolder}",
          args = function()
            local input = vim.fn.input("Args: ")
            if input == nil or input == "" then
              return {}
            end
            return vim.split(input, " +")
          end,
        },
      }

      local saved_snacks_width = nil

      local function find_snacks_picker_window()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if ft == "snacks_picker_list" or ft:match("^snacks") then
            return win
          end
        end
      end

      local function save_snacks_width()
        local win = find_snacks_picker_window()
        if win and vim.api.nvim_win_is_valid(win) then
          saved_snacks_width = vim.api.nvim_win_get_width(win)
        end
      end

      local function restore_snacks_width()
        vim.defer_fn(function()
          local win = find_snacks_picker_window()
          if win and saved_snacks_width and vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_set_width, win, saved_snacks_width)
          end
        end, 80)
      end

      local function close_snacks_and_open_ui()
        save_snacks_width()

        local ok, snacks = pcall(require, "snacks")
        if ok and snacks.picker then
          local pickers = snacks.picker.get({ tab = true })
          for _, picker in ipairs(pickers) do
            picker:close()
          end
        end

        dapui.open()
      end

      dap.listeners.before.attach.dapui_config = close_snacks_and_open_ui
      dap.listeners.before.launch.dapui_config = close_snacks_and_open_ui
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
        restore_snacks_width()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
        restore_snacks_width()
      end
    end,
    keys = {
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "Debug: Continue/Start",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "Debug: Step Over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "Debug: Step Into",
      },
      {
        "<S-F11>",
        function()
          require("dap").step_out()
        end,
        desc = "Debug: Step Out",
      },
      {
        "<F9>",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Debug: Toggle Breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<leader>dg",
        function()
          require("dap").goto_()
        end,
        desc = "Go to Line",
      },
    },
  },
}
