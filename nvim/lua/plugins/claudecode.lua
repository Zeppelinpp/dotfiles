return {
  {
    "coder/claudecode.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- Set Kimi Coding API environment variables
    init = function()
      -- Get KIMI_API_KEY
      local kimi_key = vim.fn.system("echo -n $KIMI_API_KEY")
      if kimi_key and kimi_key ~= "" then
        vim.env.ANTHROPIC_API_KEY = kimi_key
        vim.env.ANTHROPIC_BASE_URL = "https://api.kimi.com/coding/"
      else
        -- If not in shell, set directly (fallback)
        vim.env.ANTHROPIC_API_KEY = ""
        vim.env.ANTHROPIC_BASE_URL = "https://api.kimi.com/coding/"
      end
      -- Ensure PATH includes claude
      vim.env.PATH = vim.env.HOME .. "/.local/bin:" .. vim.env.PATH
    end,
    opts = {
      -- Use claude command installed in system
      terminal_cmd = vim.fn.expand("~/.local/bin/claude"),
      -- Port range configuration (optional)
      port_range = { min = 10000, max = 65535 },
      -- Auto-start Claude IDE server
      auto_start = true,
      -- Log level
      log_level = "info",
      -- Terminal provider: use "none" to manage Claude externally (e.g., in Ghostty split)
      -- Then manually run `claude --ide` in your Ghostty terminal to connect
      terminal = {
        provider = "none",
      },
    },
    -- Default keybindings configuration
    keys = {
      { "<leader>a", "", desc = "+AI/Claude" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCodeRestart<cr>", desc = "Restart Claude" },
      -- Send selection to Claude (visual mode)
      { "<leader>as", ":ClaudeCodeSend<cr>", desc = "Send to Claude", mode = "v" },
      -- Send entire file
      { "<leader>aS", "<cmd>ClaudeCodeSend<cr>", desc = "Send file to Claude" },
    },
  },
}
