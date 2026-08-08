source /usr/share/cachyos-fish-config/cachyos-config.fish

# Default editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# overwrite greeting, disabling fastfetch
function fish_greeting
end

if status is-interactive

    # Enable vi style motion
    fish_vi_key_bindings

    # Add custom paths to fish_user_paths
    set -U fish_user_paths /usr/local/go/bin $fish_user_paths
    set -U fish_user_paths $HOME/go/bin $fish_user_paths
    set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths
    set -U fish_user_paths $HOME/.local/bin $fish_user_paths
    set -U fish_user_paths $HOME/.krew/bin $fish_user_paths
    set -U fish_user_paths $HOME/.bun/bin $fish_user_paths

    # Add root directories
    set -U fish_user_paths /usr/sbin $fish_user_paths
    set -U fish_user_paths /sbin $fish_user_paths

    # Add GOPATH
    set -x GOPATH ~/go

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

    command -q atuin; and atuin init fish | source

end

export PATH="$HOME/.local/bin:$PATH"
