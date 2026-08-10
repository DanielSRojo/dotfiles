-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

--- Zellij `edit-scrollback` dumps the pane to $TMPDIR/<uuid>.dump -- highlight those as logs
vim.filetype.add({ extension = { dump = "log" } })

--- Detect kubectl edit buffers and set filetype to yaml
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("KubectlEdit", { clear = true }),
  pattern = "*/kubectl-edit-*.yaml",
  callback = function()
    vim.schedule(function()
      vim.bo.filetype = "yaml"
      vim.bo.syntax = "yaml"
    end)
  end,
})
