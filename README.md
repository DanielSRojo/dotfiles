# Dotfiles

These are my config files for my most beloved software.

The structure is reflecting the `~/.config` directory for easily applying it with stow.

## New machine

```bash
stow --adopt .        # link everything into ~/.config (--target lives in .stowrc)
bat cache --build     # required: see below

# macOS only, and only after ~/.config/nushell exists as the stow link above:
ln -s ~/.config/nushell ~/Library/Application\ Support/nushell
```

`bat` does not read `bat/themes/*.tmTheme` directly — it only sees themes from a
binary cache in `~/.cache/bat`, which is machine-local and not tracked here.
Until `bat cache --build` runs, the `--theme="GitHub-Light-High-Contrast"` in
`bat/config` silently falls back to bat's default theme, and so does delta's
`syntax-theme` in `git/config`.

## Day to day

To check changes:

```bash
stow --verbose --simulate --adopt .
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

| Tool    | Untracked file                | How it is picked up                              |
| ------- | ----------------------------- | ------------------------------------------------ |
| fish    | `fish/conf.d/*work*.fish`     | fish sources everything in `conf.d`              |
| jj      | `jj/conf.d/*work*.toml`       | jj layers `conf.d` on top of `config.toml`       |
| nu      | `nushell/autoload/*work*.nu`  | nushell sources every `.nu` in `autoload`        |
| ghostty | `ghostty/config.local`        | `config-file` at the end of `ghostty/config`     |
| nvim    | `nvim/lua/config/local.lua`   | `pcall(require, ...)` in `plugins/github-theme.lua` |
| git     | `~/.gitconfig`                | git reads it after `git/config`, so it wins      |

zellij has a single shared config and no override file: keep OS-specific
values out of it and lean on settings that parse everywhere (OSC 52 for its
clipboard, `$EDITOR` for its scrollback editor). The one thing that does vary,
its theme, comes in through ghostty instead (below). Likewise `font-thicken` in
ghostty is macOS-only in effect but harmless to parse on Linux.

### Theme

The shared default is GitHub Light High Contrast. A machine that keeps Ayu Dark
(bluebox) overrides it in three untracked files. The Ayu themes stay tracked for
this: `ghostty/themes/ayu-dark` and `bat/themes/Ayu-Dark.tmTheme`; zellij's
`ayu-dark` is a builtin.

`ghostty/config.local` covers ghostty, zellij and bat. Both `env` lines reach
every shell started inside ghostty, zellij included. ghostty's `initial-command`
hands `ZELLIJ_THEME` to zellij, which only applies it when the session is
created: run `zellij delete-session main --force` once after setting it.

```
theme = ayu-dark
env = ZELLIJ_THEME=ayu-dark
env = BAT_THEME=Ayu-Dark
```

`~/.gitconfig`, for delta, whose `syntax-theme` in `git/config` would otherwise
win over `BAT_THEME`:

```ini
[delta]
    light = false
    dark = true
    syntax-theme = Ayu-Dark
```

`nvim/lua/config/local.lua` (Ayu has no LazyVim theme here; everforest is what
nvim ran before):

```lua
return { colorscheme = "everforest" }
```

### macOS

Package management is Homebrew on macOS and pacman on Linux. Both put their
binaries somewhere the other machine does not have, so the `brew shellenv` block
at the top of `config.fish` probes for `brew` and stays inert when it is absent.
That is the only OS-specific PATH logic left in here.

Nushell is the one tool here that does not look in `~/.config` on macOS: it reads
`~/Library/Application Support/nushell`, and only consults `XDG_CONFIG_HOME` when
that variable is set. Hence the symlink in the New machine block rather than an
export: nushell may one day be the login shell, and a variable set from
`config.fish` — or from anything else nushell does not read, which includes
nix-darwin's `environment.variables`, since those ship through the `/etc/zshenv`,
`/etc/bashrc` and `/etc/fish` init files it generates — cannot tell nushell where
its own config lives. The symlink holds regardless of who launches the shell.

Two ways that symlink goes wrong. If `~/Library/Application Support/nushell`
already exists as a directory (nushell creates one, with default `config.nu` and
`env.nu`, the first time it starts without a config), `ln -s` puts the link
*inside* it and nushell keeps reading those defaults; move that directory away
first. And if `~/.config/nushell` is a real directory rather than the stow link,
`stow --adopt .` will pull nushell's generated `config.nu` into this repo on top
of the tracked one — clear it before stowing, not after. Linux needs neither the
symlink nor the export.
