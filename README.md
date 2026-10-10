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
Until `bat cache --build` runs, the light and dark themes in `bat/config`
silently fall back to bat's default theme.

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
| nvim    | `nvim/lua/config/local.lua`   | `pcall(require, ...)` in `plugins/flexoki.lua`   |
| git     | `~/.gitconfig`                | git reads it after `git/config`, so it wins      |

zellij has a single shared config and no override file: keep OS-specific
values out of it and lean on settings that parse everywhere (OSC 52 for its
clipboard, `$EDITOR` for its scrollback editor). Likewise `font-thicken` in
ghostty is macOS-only in effect but harmless to parse on Linux.

### Theme

Light by day, dark by night, on every machine with no override files. The OS
decides: COSMIC's auto-switch flips at sunrise and sunset (tracked in
`cosmic/com.system76.CosmicTheme.Mode/v1/auto_switch`); on macOS it is the
system appearance. ghostty follows it and reports each change to the programs
inside it, and everything else asks ghostty:

| Tool    | Light                      | Dark                    | Switches                         |
| ------- | -------------------------- | ----------------------- | -------------------------------- |
| ghostty | GitHub Light High Contrast | ayu-dark                | live                             |
| zellij  | github-light-high-contrast | ayu-dark                | live, `theme_light`/`theme_dark` |
| nvim    | flexoki-light              | everforest              | when `background` changes        |
| bat     | GitHub-Light-High-Contrast | Ayu-Dark                | each run, `--theme=auto`         |
| delta   | its default light syntax   | its default dark syntax | each run                         |

nvim has no Ayu theme here, hence everforest. delta has no per-mode
`syntax-theme`, so it uses its own defaults rather than `bat/themes`.

To pin one colorscheme in nvim on a machine, return it from
`nvim/lua/config/local.lua`:

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
