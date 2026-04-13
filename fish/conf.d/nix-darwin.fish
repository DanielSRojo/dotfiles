# Source nix-darwin environment (sets PATH including /run/current-system/sw/bin)
if test -f /etc/fish/nixos-env-preinit.fish
    source /etc/fish/nixos-env-preinit.fish
end
