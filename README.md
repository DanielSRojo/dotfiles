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

Everything here is shared between the Linux and the macOS box, so anything that
genuinely differs per machine lives in an untracked file that the tracked config
pulls in:

| Tool | Untracked file            | How it is picked up                        |
| ---- | ------------------------- | ------------------------------------------ |
| fish | `fish/conf.d/*work*.fish` | fish sources everything in `conf.d`        |
| jj   | `jj/conf.d/*.work.toml`   | jj layers `conf.d` on top of `config.toml` |

ghostty and zellij have a single shared config each and no override file: keep
OS-specific values out of them and lean on settings that parse everywhere (OSC
52 for zellij's clipboard, `$EDITOR` for its scrollback editor, `font-thicken`
in ghostty, which is macOS-only in effect but harmless to parse on Linux).

### macOS

Package management is Homebrew on macOS and pacman on Linux. Both put their
binaries somewhere the other machine does not have, so the `brew shellenv` block
at the top of `config.fish` probes for `brew` and stays inert when it is absent.
That is the only OS-specific PATH logic left in here.
