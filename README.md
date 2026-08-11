# Dotfiles

These are my config files for my most beloved software.

The structure is reflecting the `~/.config` directory for easily applying it with stow.

To check changes:
```bash
stow --verbose --simulate . --adopt
```

To add a new config file from target dir:
```
touch <file>
stow --adopt .
```

This will move the file's content to the touched one and replace the original with a symlink to the new one.

## Per-machine settings

Everything here is shared between the CachyOS and the macOS box, so anything that
genuinely differs per machine lives in an untracked file that the tracked config
pulls in:

| Tool    | Untracked file            | How it is picked up                               |
| ------- | ------------------------- | ------------------------------------------------- |
| ghostty | `ghostty/config.local`    | `config-file = ?config.local` in `ghostty/config` |
| fish    | `fish/conf.d/*work*.fish` | fish sources everything in `conf.d`               |
| jj      | `jj/conf.d/*.work.toml`   | jj layers `conf.d` on top of `config.toml`        |

Note that a repo-level jj config (`.jj/repo/config.toml`) outranks both, so a
repo that pins `user.email` ignores the work file.

zellij has no include mechanism, so its config is shared as-is: keep OS-specific
values out of it and lean on the defaults instead (OSC 52 for the clipboard,
`$EDITOR` for the scrollback editor).

### macOS

The shared configs are unified on the Linux values, so the Mac wants its
overrides back:

```bash
cp ghostty/config.local.example ghostty/config.local
stow .
```

