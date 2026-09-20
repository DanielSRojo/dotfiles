-- LazyVim's lang.nix extra configures nil_ls, but home.nix installs nixd, so
-- the extra alone leaves .nix files with no LSP at all: it asks for a `nil`
-- binary that is not on PATH, and fails quietly.
--
-- nixd is the deliberate choice -- it evaluates the flake, so completion and
-- go-to-definition understand NixOS and home-manager options rather than just
-- the language. The cost is that it needs this file; nil would need none.
--
-- If nixd ever goes back to nil in home.nix, delete this file with it.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = { enabled = false },
        nixd = {},
      },
    },
  },
}
