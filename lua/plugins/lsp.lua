

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
}


}






