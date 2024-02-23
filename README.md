# Dotfiles
The structure is reflecting the real directory structure for easily applying it with stow.

To check changes:
```bash
stow -nv .
```

To add a new config file:
```
touch <file>
stow --adopt .
```

This will copy the file's content to the touched one and replace the original with a symlink to the new one.

