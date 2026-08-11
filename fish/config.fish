# Add custom paths. fish_add_path is idempotent and silently skips directories
# that do not exist, so this is safe to re-run and safe to share across machines.
# Runs before the CachyOS base config below, which adds ~/.local/bin and
# ~/.cargo/bin itself; going first keeps this list's ordering authoritative.
fish_add_path /sbin /usr/sbin \
    $HOME/.bun/bin \
    $HOME/.krew/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/go/bin \
    /usr/local/go/bin \
    $HOME/Library/Python/3.9/bin

# Add GOPATH
set -gx GOPATH ~/go

# CachyOS base config (Linux only, absent on macOS)
if test -r /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish

    # The base config defines its own ls/la/ll aliases, and config.fish is
    # sourced after conf.d, so re-apply ours to keep them authoritative.
    if test -r $__fish_config_dir/conf.d/alias.fish
        source $__fish_config_dir/conf.d/alias.fish
    end
end

# Default editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# overwrite greeting, disabling fastfetch
function fish_greeting
end

if status is-interactive

    # Set up zoxide
    command -q zoxide; and zoxide init fish | source

    # Enable starship prompt
    if command -q starship
        starship init fish | source
        enable_transience
    end

    # Kubectl completion
    command -q kubectl; and kubectl completion fish | source

    # Helm completion
    command -q helm; and helm completion fish | source

    # Direnv hook
    command -q direnv; and direnv hook fish | source

    # Shell history
    command -q atuin; and atuin init fish | source

end
