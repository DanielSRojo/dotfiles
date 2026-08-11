return {
  {
    "Shatur/neovim-ayu",
    name = "ayu",
    main = "ayu",
    lazy = false,
    priority = 1000,
    opts = {
      mirage = false,
      -- ghostty owns the ANSI palette; let :terminal buffers inherit it
      terminal = false,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-dark",
    },
  },
}
