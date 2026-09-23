-- Available but not active: the colorscheme LazyVim actually loads is set in
-- everforest.lua. `lazy = true` is enough to make `:colorscheme kanagawa` work
-- -- lazy.nvim's ColorSchemePre handler loads whichever plugin ships that
-- colors/ file on demand.
--
-- Ships four: `kanagawa` (follows the `theme` below), plus `kanagawa-wave`,
-- `kanagawa-dragon` and `kanagawa-lotus` to pick one directly.
return {
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      theme = "wave", -- wave | dragon | lotus
    },
  },
}
