-- LazyVim ships mini.surround as an extra, which `:LazyExtras` would record in
-- nvim/lazyvim.json -- but that file is gitignored (it diverges per machine), so
-- the extra is imported here to keep it tracked in the repo instead.
--
-- The import carries LazyVim's own spec: the `gs` mappings (gsa add, gsd delete,
-- gsr replace, gsf/gsF find, gsh highlight) that its which-key config already
-- groups under "surround", plus a `keys` function so the plugin loads on first
-- use rather than at startup. Each of those also takes mini's `n`/`l` suffix for
-- the next/previous match, e.g. gsdn deletes the next surrounding.
--
-- The extra also sets `mappings.update_n_lines = "gsn"`, which is dead: upstream
-- mini.surround stopped mapping that action (H.apply_config never binds it) and
-- now documents it as a manual vim.keymap.set. So gsn is a lazy-load trigger
-- that resolves to nothing -- harmless, but don't expect it to prompt.
return {
  { import = "lazyvim.plugins.extras.coding.mini-surround" },
}
