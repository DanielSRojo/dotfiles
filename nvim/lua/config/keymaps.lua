-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Highlight the current buffer as a log file (timestamps, levels, etc.)
vim.keymap.set("n", "<leader>uy", function()
  vim.bo.syntax = "log"
end, { desc = "Set syntax to log" })
