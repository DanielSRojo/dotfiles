-- Make markdownlint-cli2 always use our config, regardless of nvim's cwd.
-- nvim-lint pipes the buffer over stdin, and in stdin mode markdownlint-cli2
-- only looks for a config in the exact current directory (it does NOT walk up),
-- so we pass an absolute --config to reliably disable MD013 (80-column warning).
return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = function()
    require("lint").linters["markdownlint-cli2"].args = {
      "--config",
      vim.fn.expand("~/.markdownlint-cli2.yaml"),
      "-",
    }
  end,
}
