-- Advanced snacks.nvim dashboard configuration
-- Features multi-pane layout with header, keys, recent files, projects, and git status

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>;", function() Snacks.dashboard.open() end, desc = "Dashboard" },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    vim.api.nvim_create_autocmd("BufDelete", {
      callback = function(args)
        vim.schedule(function()
          -- 检查是否还有其他非空 listed buffer
          local listed = vim.fn.getbufinfo({ buflisted = 1 })
          local has_real_buffer = false
          for _, buf in ipairs(listed) do
            if buf.bufnr ~= args.buf and buf.name ~= "" then
              has_real_buffer = true
              break
            end
          end

          if has_real_buffer then
            return
          end

          -- 避免在 explorer/picker 等特殊窗口中打开 dashboard
          local cur_buf = vim.api.nvim_get_current_buf()
          if not vim.api.nvim_buf_is_valid(cur_buf) then
            return
          end
          local ft = vim.bo[cur_buf].filetype
          if ft == "snacks_picker_list" or ft == "snacks_dashboard" or ft == "snacks_picker_input" then
            return
          end

          -- 延迟打开 dashboard，确保 explorer 的文件操作已完成
          vim.defer_fn(function()
            -- 再次检查，防止期间又有新 buffer 创建
            local final_listed = vim.fn.getbufinfo({ buflisted = 1 })
            for _, buf in ipairs(final_listed) do
              if buf.name ~= "" then
                return
              end
            end

            -- 参考 snacks 启动时的逻辑：只有一个非浮动窗口时才显示 dashboard
            -- 有 explorer 等 sidebar 时不自动显示，避免窗口布局冲突
            local wins = vim.tbl_filter(function(w)
              local b = vim.api.nvim_win_get_buf(w)
              return vim.api.nvim_win_get_config(w).relative == "" and not vim.bo[b].filetype:find("snacks")
            end, vim.api.nvim_tabpage_list_wins(0))

            if #wins ~= 1 then
              return
            end

            local buf = vim.api.nvim_win_get_buf(wins[1])
            -- buffer 必须为空（和启动时逻辑一致）
            if vim.api.nvim_buf_line_count(buf) > 1 or #(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") > 0 then
              return
            end

            Snacks.dashboard.open({ buf = buf, win = wins[1] })
          end, 150)
        end)
      end,
    })
  end,
  opts = {
    dashboard = {
      width = 60,
      row = nil,
      col = nil,
      pane_gap = 4,
      autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",

      -- Custom header (ASCII art)
      preset = {
        keys = {
          {
            icon = " ",
            key = "f",
            desc = "Find File",
            action = function()
              Snacks.picker.files()
            end,
          },
          {
            icon = " ",
            key = "n",
            desc = "New File",
            action = ":ene | startinsert",
          },
          {
            icon = " ",
            key = "g",
            desc = "Find Text",
            action = function()
              Snacks.picker.grep()
            end,
          },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files",
            action = function()
              Snacks.picker.recent()
            end,
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = function()
              Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
            end,
          },
          {
            icon = " ",
            key = "s",
            desc = "Restore Session",
            section = "session",
          },
          {
            icon = "󰒲 ",
            key = "L",
            desc = "Lazy",
            action = ":Lazy",
            enabled = package.loaded.lazy ~= nil,
          },
          {
            icon = " ",
            key = "q",
            desc = "Quit",
            action = ":qa",
          },
        },
        header = [[
    ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
    ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
    ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
        ]],
      },

      -- Advanced multi-pane layout
      sections = {
        -- Left pane: Header and key shortcuts
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },

        -- Right pane: Terminal decoration (colorful squares pattern)
        -- square-colorscript installed at ~/.local/bin/square-colorscript
        {
          pane = 2,
          section = "terminal",
          cmd = "~/.local/bin/square-colorscript 2>/dev/null || echo '    ♦ ♦ ♦ ♦ ♦ ♦'",
          height = 5,
          padding = 1,
        },

        -- Right pane: Recent files
        {
          pane = 2,
          icon = " ",
          title = "Recent Files",
          section = "recent_files",
          indent = 2,
          padding = 1,
          limit = 5,
        },

        -- Right pane: Projects
        {
          pane = 2,
          icon = " ",
          title = "Projects",
          section = "projects",
          indent = 2,
          padding = 1,
          limit = 5,
        },

        -- Right pane: Git status (only shown in git repo)
        {
          pane = 2,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = "git status --short --branch --renames 2>/dev/null || echo 'Not a git repository'",
          height = 5,
          padding = 1,
          ttl = 5 * 60, -- Cache for 5 minutes
          indent = 3,
        },

        -- Bottom: Startup time
        { section = "startup" },
      },

      -- Formats for different elements
      formats = {
        key = function(item)
          return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
        end,
      },
    },
  },
}
