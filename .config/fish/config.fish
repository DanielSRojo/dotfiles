if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Remove fish greeting
set fish_greeting

# Set nvim as editor
set -x EDITOR nvim

# Enable vi style motion
fish_vi_key_bindings

# Add custom paths to fish_user_paths
set -U fish_user_paths /usr/local/go/bin $fish_user_paths
set -U fish_user_paths $HOME/go/bin $fish_user_paths
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths
set -U fish_user_paths $HOME/.local/bin $fish_user_paths
set -U fish_user_paths $HOME/.krew/bin $fish_user_paths

# Add GOPATH
set -x GOPATH ~/go

# Import custom aliases
source ~/.config/fish/alias.sh
source ~/.config/fish/abbr.sh
source ~/.config/fish/corporate.sh

# Set up zoxide
zoxide init fish | source

# Enable starship prompt
starship init fish | source
enable_transience

# Kubectl completion
kubectl completion fish | source

# Helm completion
helm completion fish | source

# Openstack completion
openstack complete --shell=fish | source

# Direnv hook
direnv hook fish | source

