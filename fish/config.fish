# --- Environment -------------------------------------------------------------

# Homebrew on macOS: sets PATH, MANPATH, INFOPATH and HOMEBREW_* vars. Probed
# for Apple Silicon; on Linux neither exists and this is a no-op.
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

# Add custom paths. fish_add_path is idempotent and silently skips directories
# that do not exist, so this is safe to re-run and safe to share across machines.
fish_add_path /sbin /usr/sbin \
    $HOME/.bun/bin \
    $HOME/.krew/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/go/bin \
    /usr/local/go/bin

set -gx GOPATH ~/code/go
set -gx EDITOR nvim
set -gx VISUAL nvim

# Render man pages through bat. MANROFFOPT=-c works around groff's overstrike
# output, which col strips. Absorbed from the CachyOS base config.
if command -q bat
    set -gx MANROFFOPT -c
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
end

# --- Shell behaviour ---------------------------------------------------------

set -g fish_key_bindings fish_vi_key_bindings

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
