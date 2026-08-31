# Nushell reads this from ~/.config/nushell on Linux. On macOS it reads
# ~/Library/Application Support/nushell, which the README's New machine block
# symlinks here -- a symlink rather than an XDG_CONFIG_HOME export because no
# shell rc can tell nushell where its own config lives once nushell is the shell.
#
# Everything drop-in lives in autoload/: nushell sources every .nu file in
# $nu.user-autoload-dirs after this file, in name order. That is the conf.d
# equivalent, so abbreviations and per-machine snippets live there, not here.

# --- Shell behaviour ---------------------------------------------------------

$env.config.edit_mode = 'vi'
$env.config.show_banner = false

# Deliberately not ported from config.fish: PATH assembly, the brew shellenv
# probe, EDITOR/GOPATH/MANPAGER, and the starship/zoxide/atuin/direnv/kubectl
# init block. Nushell inherits the environment of whatever launched it, so this
# package is abbreviations-only until nushell becomes a login shell here.
