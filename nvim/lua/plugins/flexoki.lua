-- Available but not active: the colorscheme LazyVim actually loads is set in
-- github-theme.lua. Flexoki is not one of the two colorschemes LazyVim bundles
-- (tokyonight, catppuccin), so it needs its own spec. `lazy = true` overrides the
-- `defaults.lazy = false` in config/lazy.lua on purpose: LazyVim loads the
-- colorscheme itself during startup, so eager-loading only costs startup time.
--
-- Ships `flexoki-light` and `flexoki-dark`; plain `flexoki` follows 'background'.
-- Light matches ghostty's "Flexoki Light" and zellij/themes/flexoki-light.kdl.
return {
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    version = false,
    lazy = true,
  },
}
