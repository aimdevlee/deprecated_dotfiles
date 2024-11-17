return {
  {
    "letieu/wezterm-move.nvim",
    keys = {
      {
        "<C-h>",
        function()
          require("wezterm-move").move("h")
        end,
      },
      {
        "<C-j>",
        function()
          require("wezterm-move").move("j")
        end,
      },
      {
        "<C-k>",
        function()
          require("wezterm-move").move("k")
        end,
      },
      {
        "<C-l>",
        function()
          require("wezterm-move").move("l")
        end,
      },
    },
  },
  -- {
  --   "akinsho/toggleterm.nvim",
  --   version = "*",
  --   keys = {
  --
  --     {
  --       "<leader>tt",
  --       "<cmd>ToggleTerm<CR>",
  --       desc = "terminal",
  --       mode = { "n" },
  --     },
  --   },
  --   opts = {
  --     direction = "horizontal",
  --   },
  -- },
  -- {
  --   "willothy/flatten.nvim",
  --   lazy = false,
  --   priority = 1001,
  --   opts = {
  --     callbacks = {
  --       pre_open = function()
  --         -- for lazygit.nvim
  --         local win = vim.api.nvim_get_current_win()
  --         local config = vim.api.nvim_win_get_config(win)
  --         if config.relative ~= "" then
  --           vim.api.nvim_win_close(win, false)
  --         end
  --       end,
  --     },
  --     window = {
  --       open = "alternate",
  --     },
  --   },
  -- },
}
