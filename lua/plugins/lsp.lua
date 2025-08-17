

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("nvim-tree.api").tree.open()
    local buftype = vim.api.nvim_get_option_value("filetype", { buf = 0 })
    if buftype == "NvimTree" then
      vim.cmd("wincmd l") -- move right to code buffer
      end
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("NvimTreeCloseIfLast", { clear = true }),
  pattern = "NvimTree_*",
  callback = function()
    local layout = vim.api.nvim_call_function("winlayout", {})
    if layout[1] == "leaf" and vim.bo.filetype == "NvimTree" then
      vim.cmd("quit")
    end
  end,
})


return {
  -- Mason: LSP/DAP installer
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
  },

  -- Bridges Mason and LSPConfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls", -- JavaScript/TypeScript
          "pyright",  -- Python
        },
      })
    end,
  },

  -- LSPConfig
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local lspconfig = require("lspconfig")

      -- JavaScript/TypeScript
      lspconfig.ts_ls.setup({})

      -- Python
      lspconfig.pyright.setup({})
     -- Diagnostics config
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
      update_in_insert = false,
      severity_sort = true,
    })

    vim.api.nvim_create_autocmd("CursorHold", {
      callback = function()
        vim.diagnostic.open_float(nil, { focus = false })
      end,
    })

    vim.o.updatetime = 300 
     end,
  },
  -- Completion + Snippets
 

{
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    -- Load VSCode-style snippets
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
      }),
    })
  end,
},

  -- File tree
  { "nvim-tree/nvim-tree.lua", config = function()
    require("nvim-tree").setup({
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      view = {
        width = 30,
        side = "left",
      },
    })
end,
},
  

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Statusline
  { "nvim-lualine/lualine.nvim", config = true },

  -- Git
  { "lewis6991/gitsigns.nvim", config = true },
  { "tpope/vim-fugitive" },
  {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("lint").linters_by_ft = {
      python = { "ruff" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
},
  -- DAP (debugger)
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap" } },

{
  "mfussenegger/nvim-dap-python",
  ft = "python",
  dependencies = {
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio"
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    vim.keymap.set("n", "<F5>", function() dap.continue() end)
    vim.keymap.set("n", "<F10>", function() dap.step_over() end)
    vim.keymap.set("n", "<F11>", function() dap.step_into() end)
    vim.keymap.set("n", "<F12>", function() dap.step_out() end)
    vim.keymap.set("n", "<Leader>b", function() dap.toggle_breakpoint() end)
    vim.keymap.set("n", "<Leader>B", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end)
    vim.keymap.set("n", "<Leader>dr", function() dap.repl.open() end)
    
	dap.configurations.typescript = {
		{
    	type = "pwa-node",
    	request = "launch",
    	name = "Launch current file (ts-node)",
    	program = "${file}",
    	cwd = vim.fn.getcwd(),
    	runtimeExecutable = "node",
    	runtimeArgs = { "-r", "ts-node/register" },
    	sourceMaps = true,
	-- ~/.config/nvim/lua/plugins/lsp.lua    
	protocol = "inspector",
    	skipFiles = { "<node_internals>/**", "node_modules/**" },
  	},
	}

    require("dap-python").setup("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python")

	require("dap-vscode-js").setup({
  	debugger_path = vim.fn.stdpath("data") .. "/vscode-js-debug", -- this is correct for Windows too
  	adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
	})

    dapui.setup()

    -- Auto-open/close dap-ui on session start/end
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end,
},

  -- Refactoring
  { "ThePrimeagen/refactoring.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- UI polish
  { "folke/noice.nvim", event = "VeryLazy", config = true, dependencies = { "MunifTanjim/nui.nvim" } },
  { "stevearc/dressing.nvim", config = true },

  -- Virtual env selector
  { "linux-cultist/venv-selector.nvim", branch="regexp" ,opts = {} },


{
  "mxsdev/nvim-dap-vscode-js",
  
  dependencies = { "mfussenegger/nvim-dap" },
  config = function()
    require("dap-vscode-js").setup({
      debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug", -- install path
      adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
    })
  end,
},
{
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("bufferline").setup({})
  end,
},

 {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      strategies = {
        -- Change the default chat adapter
        chat = {
          adapter = 'mistral_test',
          inline = 'mistral_test',
        },
      },
      adapters = {
        mistral_test = function()

          return require('codecompanion.adapters').extend('ollama', {
            name = 'mistral_test', -- Give this adapter a different name to differentiate it from the default ollama adapter
            schema = {
              model = {
                default = 'mistral:latest',
              },
            },
          })
        end,
      },
      opts = {
        log_level = 'DEBUG',
      },
      display = {
        diff = {
          enabled = true,
          close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
          layout = 'vertical', -- vertical|horizontal split for default provider
          opts = { 'internal', 'filler', 'closeoff', 'algorithm:patience', 'followwrap', 'linematch:120' },
          provider = 'default', -- default|mini_diff
        },
      },
    },
  },

}






