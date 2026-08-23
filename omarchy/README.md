# omarchy/shell.json

The note lives here rather than inside `shell.json` because the shell reads that
file with a strict `JSON.parse` (a comment makes it fall back to the defaults
without saying so) and writes it back with `JSON.stringify`, which would drop
any comment on the first rewrite anyway.

The Omarchy shell rewrites `shell.json` atomically (temp file plus rename), so
every change made through the shell itself — `omarchy bar ...`, `omarchy plugin
enable`, a settings-panel toggle — replaces the symlink with a regular file and
silently detaches the config from this repo. Nothing warns about it; the tracked
copy just stops changing. To re-attach after such a change, from the repo root:

```bash
cp ~/.config/omarchy/shell.json omarchy/shell.json
rm ~/.config/omarchy/shell.json
ln -s ../../.dotfiles/omarchy/shell.json ~/.config/omarchy/shell.json
```

Those rewrites also re-sort the keys, so the tracked copy is kept in the shell's
own output order to keep diffs small. `idle.lock` is set to a day rather than
`0`: the shell treats `0` as "lock immediately on idle", not "never lock".
