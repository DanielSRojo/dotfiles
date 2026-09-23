-- Everforest is not one of the two colorschemes LazyVim bundles (tokyonight,
-- catppuccin), so it needs its own spec. `lazy = true` overrides the
-- `defaults.lazy = false` in config/lazy.lua on purpose: LazyVim loads the
-- colorscheme itself during startup, so eager-loading only costs startup time.
-- That is also why the upstream README's `priority = 1000` is absent -- it
-- exists to win a load-order race that LazyVim does not have.
return {
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = true,
    -- lazy.nvim cannot derive the module name from `everforest-nvim` on its own
    -- ("Lua module not found for config of everforest-nvim"), so point it at the
    -- module explicitly. `opts` is then handed to `require("everforest").setup()`.
    main = "everforest",
    opts = {
      background = "hard", -- soft | medium | hard
      ui_contrast = "high", -- high | low
      italics = true,
      float_style = "dim", -- bright | dim
      diagnostic_virtual_text = "coloured",
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "everforest" } },
}
