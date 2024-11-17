return {
  {
    "kevinhwang91/nvim-ufo",
    event = "VeryLazy",
    dependencies = "kevinhwang91/promise-async",
    keys = {
      {
        "zR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      {
        "zM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
    },
    init = function()
      -- Need to disable zM, zR during init, because it will change foldlevel
      -- if zM/zR executed before the keymap settings of nvim-ufo has been effective.
      local ufo_not_ready = vim.schedule_wrap(function()
        vim.notify(
          "nvim-ufo is yet to be initialized, please try again later...",
          vim.log.levels.WARN,
          { timeout = 500, title = "nvim-ufo" }
        )
      end)
      vim.keymap.set("n", "zM", ufo_not_ready, { silent = true })
      vim.keymap.set("n", "zR", ufo_not_ready, { silent = true })
    end,
    config = function()
      local ufo = require("ufo")

      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99

      local ftMap = {
        vim = "indent",
        python = { "indent" },
        git = "",
        dashboard = "",
      }

      --- lsp -> treesitter -> indent
      ---@param bufnr number
      ---@return Promise
      local function customizeSelector(bufnr)
        local function handleFallbackException(err, providerName)
          if type(err) == "string" and err:match("UfoFallbackException") then
            return require("ufo").getFolds(bufnr, providerName)
          else
            return require("promise").reject(err)
          end
        end
        return require("ufo")
          .getFolds(bufnr, "lsp")
          :catch(function(err)
            return handleFallbackException(err, "treesitter")
          end)
          :catch(function(err)
            return handleFallbackException(err, "indent")
          end)
      end

      local opts = {
        open_fold_hl_timeout = 150,
        provider_selector = function(bufnr, filetype)
          return ftMap[filetype] or customizeSelector
        end,
        enable_get_fold_virt_text = true,
        fold_virt_text_handler = function(virt_text, lnum, end_lnum, width, truncate, ctx)
          local counts = (" ( %d)"):format(end_lnum - lnum + 1)
          local ellipsis = "⋯"
          local padding = ""

          ---@type string
          local end_text = vim.api.nvim_buf_get_lines(ctx.bufnr, end_lnum - 1, end_lnum, false)[1]
          ---@type UfoExtmarkVirtTextChunk[]
          local end_virt_text = ctx.get_fold_virt_text(end_lnum)

          -- Post-process end line: show only if it's a single word and token
          -- e.g., { ⋯ }  ( ⋯ )  [{( ⋯ )}]  function() ⋯ end  foo("bar", { ⋯ })
          -- Trim leading whitespaces in end_virt_text
          if #end_virt_text >= 1 and vim.trim(end_virt_text[1][1]) == "" then
            table.remove(end_virt_text, 1) -- e.g., {"   ", ")"} -> {")"}
          end

          -- if the end line consists of a single 'word' (not single token)
          -- this could be multiple tokens/chunks, e.g. `end)` `})`
          if #vim.split(vim.trim(end_text), " ") == 1 then
            if end_virt_text[1] ~= nil then
              end_virt_text[1][1] = vim.trim(end_virt_text[1][1]) -- trim the first token, e.g., "   }" -> "}"
            end
          else
            end_virt_text = {}
          end

          -- Process virtual text, with some truncation at virt_text
          local suffixWidth = (2 * vim.fn.strdisplaywidth(ellipsis)) + vim.fn.strdisplaywidth(counts)
          for _, v in ipairs(end_virt_text) do
            suffixWidth = suffixWidth + vim.fn.strdisplaywidth(v[1])
          end
          if suffixWidth > 10 then
            suffixWidth = 10
          end

          local target_width = width - suffixWidth
          local cur_width = 0

          -- the final virtual text tokens to display.
          local result = {}

          for _, chunk in ipairs(virt_text) do
            local chunk_text = chunk[1]

            local chunk_width = vim.fn.strdisplaywidth(chunk_text)
            if target_width > cur_width + chunk_width then
              table.insert(result, chunk)
            else
              chunk_text = truncate(chunk_text, target_width - cur_width)
              local hl_group = chunk[2]
              table.insert(result, { chunk_text, hl_group })
              chunk_width = vim.fn.strdisplaywidth(chunk_text)

              if cur_width + chunk_width < target_width then
                padding = padding .. (" "):rep(target_width - cur_width - chunk_width)
              end
              break
            end
            cur_width = cur_width + chunk_width
          end

          table.insert(result, { " " .. ellipsis .. " ", "UfoFoldedEllipsis" })

          -- Also truncate end_virt_text to suffixWidth.
          cur_width = 0
          local j = #result
          for i, v in ipairs(end_virt_text) do
            table.insert(result, v)
            cur_width = cur_width + #v[1]
            while cur_width > suffixWidth and j + 1 < #result do
              cur_width = cur_width - #result[j + 1][1]
              result[j + 1][1] = ""
              j = j + 1
            end
          end
          if cur_width > suffixWidth then
            local text = result[#result[1]][1]
            result[#result][1] = truncate(text, suffixWidth)
          end

          table.insert(result, { counts, "MoreMsg" })
          table.insert(result, { padding, "" })

          return result
        end,
      }

      ufo.setup(opts)
    end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    keys = {
      { "<leader>d", "<cmd>DBUIToggle<cr>", desc = "DBUI" },
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    -- stylua: ignore
    keys = {
      { "<leader>sn", "", desc = "+noice"},
      { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
      { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
      { "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)" },
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = {"i", "n", "s"}},
    },
    config = function()
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end

      local opts = {
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        routes = {
          {
            filter = {
              event = "msg_show",
              any = {
                { find = "%d+L, %d+B" },
                { find = "; after #%d+" },
                { find = "; before #%d+" },
              },
            },
            view = "mini",
          },
        },
        cmdline = {
          view = "cmdline",
        },
      }

      require("noice").setup(opts)
    end,
  },
  {
    "mistricky/codesnap.nvim",
    build = "make",
    -- keys = {
    --   { "<leader>cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "clipboard" },
    --   { "<leader>cs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "file" },
    --   { "<leader>ca", "<cmd>CodeSnapASCII<cr>", mode = "x", desc = "ascii" },
    --   { "<leader>chc", "<cmd>CodeSnapHighlight<cr>", mode = "x", desc = "clipboard with highlight" },
    --   { "<leader>chs", "<cmd>CodeSnapHighlight<cr>", mode = "x", desc = "save with highlight" },
    -- },
    opts = {
      code_font_family = "Cica",
      save_path = "~/Pictures",
      has_breadcrumbs = true,
      bg_theme = "bamboo",
      has_line_number = true,
      watermark = "",
      bg_padding = 0,
    },
  },
  {
    "echasnovski/mini.nvim",
    lazy = true,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "alpha",
          "dashboard",
          "fzf",
          "help",
          "lazy",
          "lazyterm",
          "mason",
          "neo-tree",
          "notify",
          "toggleterm",
          "Trouble",
          "trouble",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
    config = function()
      require("mini.icons").setup()
      require("mini.ai").setup()
      require("mini.surround").setup()
      require("mini.indentscope").setup({
        symbol = "│",
      })
    end,
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      debug = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      quickfile = { enabled = false },
      statuscolumn = { enabled = false },
      words = { enabled = true },
      styles = {
        notification = {
          wo = { wrap = true }, -- Wrap notifications
        },
      },
    },
    keys = {
      -- stylua: ignore start
      { "<leader>nh", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
      { "<leader>nH", function() Snacks.notifier.show_history() end, desc = "Show Notification History" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
      { "<leader>bD", function() Snacks.bufdelete.all() end, desc = "Delete All Buffers" },
      { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete Other Buffers" },
      { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
      { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
      { "<leader>cR", function() Snacks.rename() end, desc = "Rename File" },
      { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal" },
      { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
      { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
      -- stylua: ignore end
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- stylua: ignore start
          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>tL")
          Snacks.toggle.diagnostics():map("<leader>td")
          Snacks.toggle.line_number():map("<leader>tl")
          Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>tc")
          Snacks.toggle.treesitter():map("<leader>tT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>tb")
          Snacks.toggle.inlay_hints():map("<leader>th")
          -- stylua: ignore end
        end,
      })
    end,
  },
  { "nvzone/showkeys", cmd = "ShowkeysToggle" },
}
