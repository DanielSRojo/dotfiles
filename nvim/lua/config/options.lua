-- Options are automatically loaded before lazy.nvim startup.
-- Defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
require("config.remote_clipboard").setup()

vim.o.background = "dark"
vim.opt.relativenumber = false
vim.g.autoformat = false
