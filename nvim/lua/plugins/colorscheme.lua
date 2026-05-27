return {
  -- add flexoki
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = false,
    },
    config = function(_, opts)
      require("flexoki").setup(opts)
    end,
  },

  -- Configure LazyVim to load flexoki
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "flexoki-dark",
    },
  },
}
