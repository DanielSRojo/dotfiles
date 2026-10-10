-- Available but not active: the colorscheme LazyVim actually loads is set in
-- flexoki.lua. github-nvim-theme is not one of the two colorschemes LazyVim
-- bundles (tokyonight, catppuccin), so it needs its own spec. `lazy = true`
-- overrides the `defaults.lazy = false` in config/lazy.lua on purpose: LazyVim
-- loads the colorscheme itself during startup, so eager-loading only costs
-- startup time.
--
-- Ships every GitHub variant as its own colorscheme (github_light,
-- github_dark_dimmed, ...). High contrast light matches ghostty's
-- "GitHub Light High Contrast" and zellij/themes/github-light-high-contrast.kdl.
return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    version = false,
    lazy = true,
    -- The module is `github-theme`, which lazy.nvim cannot derive from the repo
    -- name; `opts` is then handed to `require("github-theme").setup()`.
    main = "github-theme",
    opts = {},
  },
}
