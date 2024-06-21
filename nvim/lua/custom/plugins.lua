local plugins = {

  {
    "christoomey/vim-tmux-navigator",
    lazy = false
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "gopls",
        "golines",
        "goimports",
        "gomodifytags",
        "rust-analyzer",
      },
    },
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end
  },

  { "nvim-neotest/nvim-nio" },

  {
    "mfussenegger/nvim-dap",
    init = function()
      require("core.utils").load_mappings("dap")
    end
  },

  {
    "dreamsofcode-io/nvim-dap-go",
    ft = "go",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function(_, opts)
      local dap = require('dap')
      dap.configurations.go = {
       {
         name = "Launch cmd/main.go",
         type = "go",
         request = "launch",
         mode = "debug",
         program = "${workspaceFolder}/cmd/main.go",
      },
    }
      require("dap-go").setup(opts)
      require("core.utils").load_mappings("dap_go")
    end
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },

  {
    "nvimtools/none-ls.nvim",
    ft = "go",
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },

  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
      require("core.utils").load_mappings("gopher")
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },

  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function ()
      vim.g.rustfmt_autosave = 1
    end,
  },

  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = "neovim/nvim-lspconfig",
    opts = function ()
      return require "custom.configs.rust-tools"
    end,
    config = function (_, opts)
      require('rust-tools').setup(opts)
    end,
  },

  {
    'saecki/crates.nvim',
    ft = {"rust", "toml"},
    config = function (_, opts)
      local crates = require('crates')
      crates.setup(opts)
      crates.show()
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    opts = function ()
      local M = require "plugins.configs.cmp"
      table.insert(M.sources, {name = "crates"})
      return M
    end,
  },

  -- Obsidian plugin
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    event = {
      "BufReadPre " .. vim.fn.expand "~" .. "/.obsidian/**.md",
      "BufNewFile " .. vim.fn.expand "~" .. "/.obsidian/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/.obsidian/",
        },
      },
    },
  },

  -- Escape vim with jk and jj (removes delay)
  {
    "max397574/better-escape.nvim",
    lazy = false,
    config = function()
      require("better_escape").setup()
    end,
  },

  -- Dim inactive portions of code 
  {
    "folke/twilight.nvim",
    lazy = false,
  },

  -- Highlight TODO: comments
  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {}
  },

  -- Modify surroundings 
  {
    "tpope/vim-surround",
    lazy = false,
  },

  -- Distraction free
  {
    "junegunn/goyo.vim",
    ft = "md"
  },

  -- Vim for writters
  {
    "preservim/vim-pencil",
    ft = "md",
    config = function()
      vim.g.pencil_wrap_at = 80
    end
  },

  -- Code snapshots
  {
    "mistricky/codesnap.nvim",
    cmd = "CodeSnapPreviewOn",
    build = "make",
    opts = {
      mac_window_bar = true,
      opacity = false,
      watermark = "Daniel S. Rojo",
      editor_font_family = "FiraCode Nerd Font",
      preview_title = "LibreCode",
      watermark_font_family = "Pacifico",
    },
    config = function (_, opts)
      require("codesnap").setup(opts)
    end
  },

  -- Golang plugin
  -- TODO: review compatibility with other plugins
  {
    "ray-x/go.nvim",
    dependencies = {  -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup()
    end,
    event = {"CmdlineEnter"},
    ft = {"go", 'gomod'},
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  }
}
return plugins
