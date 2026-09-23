# --- Environment -------------------------------------------------------------

# Homebrew on macOS: sets PATH, MANPATH, INFOPATH and HOMEBREW_* vars.
# On Linux neither exists and this is a no-op.
# Runs before fish_add_path below so that list stays authoritative for ordering.
for brew_prefix in /opt/homebrew /usr/local
    if test -x $brew_prefix/bin/brew
        $brew_prefix/bin/brew shellenv | source
        break
    end
end
set -e brew_prefix

# atuin's own env file, which puts its bin dir on PATH. Must precede the
# `command -q atuin` check further down.
if test -r $HOME/.atuin/bin/env.fish
    source $HOME/.atuin/bin/env.fish
end

fish_add_path -g /sbin /usr/sbin \
    $HOME/.bun/bin \
    $HOME/.krew/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/go/bin \
    /usr/local/go/bin

# Packages installed by nix (see ~/code/github.com/danielsrojo/nix) must win
# over the pacman copies they replace. --move hoists these to the front, ahead
# of /sbin, which is a symlink to /usr/bin on Arch and so would otherwise put
# every distro binary first.
fish_add_path -gm $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin

set -gx GOPATH ~/code/go
set -gx EDITOR nvim
set -gx VISUAL nvim

# Point the docker CLI at podman's socket, so `docker` and anything shelling out
# to it (the pluginetes MCP launchers, for one) drive the podman machine without
# a Docker daemon.
#
# Derived from $TMPDIR instead of hardcoded: podman puts this socket under the
# per-user macOS temp dir, which is what $TMPDIR already holds. Guarded on the
# socket existing so a stopped podman machine leaves DOCKER_HOST unset rather
# than pinning docker to a dead socket and masking whatever context (OrbStack,
# colima) is actually up. No-op on Linux, where TMPDIR is unset.
if set -q TMPDIR
    set -l podman_sock (string trim -r -c / -- $TMPDIR)/podman/podman-machine-default-api.sock
    test -S $podman_sock; and set -gx DOCKER_HOST "unix://$podman_sock"
end

# Render man pages through bat. MANROFFOPT=-c works around groff's overstrike
# output, which col strips.
if command -q bat
    set -gx MANROFFOPT -c
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
end

# --- Shell behaviour ---------------------------------------------------------

set -g fish_key_bindings fish_vi_key_bindings

# Suppress the default "Welcome to fish" banner
function fish_greeting
end

# Timestamped history
function history
    builtin history --show-time='%F %T ' $argv
end

# --- Interactive tooling -----------------------------------------------------

if status is-interactive
    command -q zoxide; and zoxide init fish | source
    command -q kubectl; and kubectl completion fish | source
    command -q helm; and helm completion fish | source
    command -q direnv; and direnv hook fish | source
    command -q atuin; and atuin init fish | source

    if command -q starship
        starship init fish | source
        enable_transience
    end
end
