-- Flexoki is not one of the two colorschemes LazyVim bundles (tokyonight,
-- catppuccin), so it needs its own spec. `lazy = true` overrides the
-- `defaults.lazy = false` in config/lazy.lua on purpose: LazyVim loads the
-- colorscheme itself during startup, so eager-loading only costs startup time.
--
-- Ships `flexoki-light` and `flexoki-dark`; plain `flexoki` follows 'background'.
--
-- The colorscheme follows 'background', which nvim sets from what the terminal
-- reports, so it tracks ghostty's light/dark switch. Light is flexoki-light;
-- dark is everforest, as there is no Ayu for nvim here. An untracked
-- lua/config/local.lua returning `{ colorscheme = "..." }` pins one colorscheme
-- instead (see the README).
local ok, machine = pcall(require, "config.local")
local pinned = ok and type(machine) == "table" and machine.colorscheme
local by_background = { light = "flexoki-light", dark = "everforest" }

-- Remember what was applied rather than reading `g:colors_name`: flexoki names
-- both variants plain `flexoki`, so that check would never match flexoki-light.
-- It is set before loading because loading one sets 'background' again, which
-- re-enters `apply` and must find it already done.
local applied

local function apply()
  local name = pinned or by_background[vim.o.background]
  if applied ~= name then
    applied = name
    vim.cmd.colorscheme(name)
  end
end

return {
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    version = false,
    lazy = true,
    -- `init` runs at startup even for a lazy plugin, early enough to catch the
    -- terminal's first answer, which can land after LazyVim has already loaded a
    -- colorscheme. `nested` lets
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
