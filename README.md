# Dotfiles

These are my config files for my most beloved software.

The structure is reflecting the `~/.config` directory for easily applying it with stow.

To check changes:
```bash
stow --verbose --simulate . --adopt
```

To add a new config file from target dir:
```
touch <file>
stow --adopt .
```

This will move the file's content to the touched one and replace the original with a symlink to the new one.

