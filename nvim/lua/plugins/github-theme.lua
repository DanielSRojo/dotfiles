-- github-nvim-theme is not one of the two colorschemes LazyVim bundles
-- (tokyonight, catppuccin), so it needs its own spec. `lazy = true` overrides the
-- `defaults.lazy = false` in config/lazy.lua on purpose: LazyVim loads the
-- colorscheme itself during startup, so eager-loading only costs startup time.
--
-- Ships every GitHub variant as its own colorscheme (github_light,
-- github_dark_dimmed, ...). High contrast light matches ghostty's
-- "GitHub Light High Contrast" and zellij/themes/github-light-high-contrast.kdl.
--
-- The colorscheme follows 'background', which nvim sets from what the terminal
-- reports, so it tracks ghostty's light/dark switch. Dark is everforest: there is
-- no Ayu for nvim here. An untracked lua/config/local.lua returning
-- `{ colorscheme = "..." }` pins one colorscheme instead (see the README).
local ok, machine = pcall(require, "config.local")
local pinned = ok and type(machine) == "table" and machine.colorscheme
local by_background = { light = "github_light_high_contrast", dark = "everforest" }

local function apply()
  local name = pinned or by_background[vim.o.background]
  if vim.g.colors_name ~= name then
    vim.cmd.colorscheme(name)
  end
end

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
    -- `init` runs at startup even for a lazy plugin, early enough to catch the
    -- terminal's first answer, which can land after LazyVim has already loaded a
    -- colorscheme. Loading one can set 'background' itself; `apply` is a no-op
    -- once the right colorscheme is in, so that does not loop. `nested` lets
    -- `:colorscheme` fire ColorSchemePre, which is how lazy.nvim loads the plugin
    -- that ships it, and ColorScheme, which other plugins repaint on.
    init = function()
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        nested = true,
        callback = apply,
      })
    end,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = apply } },
}
