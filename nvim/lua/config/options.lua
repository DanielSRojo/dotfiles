-- Options are automatically loaded before lazy.nvim startup.
-- Defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
require("config.remote_clipboard").setup()

vim.o.background = "dark"
vim.opt.relativenumber = false
-- Format on write everywhere. This is LazyVim's default, but spell it out so a
-- future `:LazyExtras`/starter sync doesn't quietly flip it back off.
-- `<leader>uf` toggles it per buffer, `<leader>uF` globally.
vim.g.autoformat = true
