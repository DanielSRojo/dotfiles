-- Mason is disabled. Every language server, formatter and linter comes from
-- nixpkgs via home.nix instead: pinned by flake.lock, rebuilt with the system,
-- and rolled back with the generation.
--
-- Left enabled, Mason downloads a second, unpinned copy of each tool into
-- ~/.local/share/nvim/mason and puts it ahead of the nix one on nvim's PATH --
-- undeclared mutable state that no config describes, which is the thing the
-- move off Arch was meant to end.
--
-- Nothing else needs to change: LazyVim configures whatever it finds on PATH.
--
-- Names are the `mason-org/*` ones. LazyVim maps the older `williamboman/*`
-- specs onto these (see lazyvim/util/plugin.lua), so disabling those instead
-- would silently do nothing.
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
}
