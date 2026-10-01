-- Lint each markdown buffer with *its own* directory's rules, not nvim's cwd's.
--
-- nvim-lint pipes the buffer to markdownlint-cli2 over stdin, so the linter has
-- no file path to anchor on and resolves config by walking up from the process
-- cwd. Open /tmp/notes.md while nvim sits in a repo and it gets linted with that
-- repo's rules. Passing `--config` does NOT fix this: a config found by walking
-- up from cwd always beats `--config`.
--
-- So recompute cwd per lint run (declaring the linter as a function is how
-- nvim-lint supports that) and anchor it to the buffer's own directory. Buffers
-- under /tmp find nothing up that tree and fall back to the `--config` default,
-- ~/.markdownlint-cli2.yaml, which turns off MD013 (80-column warning).
return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = function()
    local lint = require("lint")
    local base = lint.linters["markdownlint-cli2"]
    if type(base) == "function" then
      return
    end

    lint.linters["markdownlint-cli2"] = function()
      local linter = vim.deepcopy(base)
      linter.args = { "--config", vim.fn.expand("~/.markdownlint-cli2.yaml"), "-" }

      local fname = vim.api.nvim_buf_get_name(0)
      local dir = fname ~= "" and vim.fs.dirname(fname) or nil
      linter.cwd = (dir and vim.fn.isdirectory(dir) == 1) and dir or vim.fn.getcwd()

      return linter
    end
  end,
}
