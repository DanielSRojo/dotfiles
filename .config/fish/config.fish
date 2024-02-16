if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Enable starship prompt
starship init fish | source

# Enable transient promt
enable_transience

# Add custom paths to fish_user_paths
set -U fish_user_paths $HOME/.local/bin $fish_user_paths

# Set up zoxide
zoxide init fish | source

# Enable vi style motion
fish_vi_key_bindings

# Import custom aliases
source ~/.config/fish/alias.sh
