# Vi style motion.
#
# Set here rather than in config.fish, and named to sort first in conf.d, so it
# is already in effect when the CachyOS base config is sourced from config.fish
# (after conf.d). That config binds ! and $ for history expansion and branches
# on $fish_key_bindings to choose insert mode; applying the bindings from
# config.fish instead would run afterwards and discard those binds.
set -g fish_key_bindings fish_vi_key_bindings
