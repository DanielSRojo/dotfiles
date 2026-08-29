# omarchy/shell.json

The note lives here rather than inside `shell.json` because the shell reads that
file with a strict `JSON.parse` (a comment makes it fall back to the defaults
without saying so) and writes it back with `JSON.stringify`, which would drop
any comment on the first rewrite anyway.

The Omarchy shell rewrites `shell.json` atomically (temp file plus rename), so
every change made through the shell itself — `omarchy bar ...`, `omarchy plugin
enable`, a settings-panel toggle — replaces the symlink with a regular file and
silently detaches the config from this repo. Nothing warns about it; the tracked
copy just stops changing. To re-attach after such a change, from the repo root:

```bash
cp ~/.config/omarchy/shell.json omarchy/shell.json
rm ~/.config/omarchy/shell.json
ln -s ../../.dotfiles/omarchy/shell.json ~/.config/omarchy/shell.json
```

Those rewrites also re-sort the keys, so the tracked copy is kept in the shell's
own output order to keep diffs small. `idle.lock` is set to a day rather than
`0`: the shell treats `0` as "lock immediately on idle", not "never lock".

`idle.suspend` is not an Omarchy key. The stock idle service only knows the
screensaver and lock steps, so `plugins/dsrojo.suspend` adds a third one. The
shell takes a valid user `shell.json` as canonical instead of deep-merging it
over the defaults, so an unknown key under `idle` reaches the plugin untouched
and survives the shell's own rewrites.

# omarchy/plugins/dsrojo.suspend

Suspends the machine after `idle.suspend` seconds idle. A standalone service
plugin rather than another patch in `bin/shell-clone-patches.py`: that script
re-clones from the package and re-applies one-line string swaps, and a new
property plus timer plus config read is far more than a swap. Nothing here
shadows a first-party id, so `omarchy update` leaves it alone entirely.

logind's own `IdleAction=suspend` is not the answer. Nothing in the Hyprland
session sets the logind idle hint — `loginctl show-session -p IdleHint` stays
`no` however long the session sits — so `IdleAction` would never fire. The
Wayland `ext-idle-notify` monitor the shell already uses is the only idle signal
that works, which is why this has to live inside `omarchy-shell`.

It honours the stay-awake state file the stock idle service and the indicator
share, so one toggle holds off blank, lock and suspend together, and it sets
`respectInhibitors` so a media player blocks the suspend and not just the blank.
A missing or non-positive `idle.suspend` means never — `0` cannot mean
"immediately" the way it does for `idle.lock`.

Locking before suspend is deliberately off: `omarchy-sleep-lock.service` is
disabled in the user manager, matching the `idle.lock` choice above, so the
machine resumes straight to the desktop. `systemctl --user enable --now
omarchy-sleep-lock.service` reverses that.

Stow links the plugin directory rather than its files, and the shell's
`inotifywait` watcher does not follow that symlink, so edits made here do not
hot-reload. Run `omarchy restart shell` after changing `Service.qml`.

Check what it is doing with `omarchy-shell suspendOnIdle status`; it logs to the
journal (`journalctl --user -b | grep suspend-on-idle`).

# omarchy/plugins/dsrojo.bar-icons

Scales the bar's icon glyphs on their own, driven by `bar.iconScale` in
`shell.json` (another key Omarchy does not define, kept by the shell for the
same reason `idle.suspend` is).

Omarchy exposes exactly one sizing knob for the shell, `[font] base-size` in
`~/.config/omarchy/shell.toml`, and it is the rem root for everything: raising
it until the bar icons read well also grows the clock, the panels, the menu and
the notifications, and it only moves the icons by its own ratio anyway — 12 to
14 takes them from 13px to 15px, which is not enough to notice.

`Style.bar` does have the right tokens — `icon-font`, `icon-canvas`,
`icon-slot` — but they cannot be set. `Style.applyShellValues` only reads
`size-horizontal`, `size-vertical` and `scale-with-font` out of a theme's
`[bar]` section and drops every other key, so writing `icon-font` into
`shell.toml` parses fine and changes nothing. `Style.barOverrides` is a plain
writable property though, and `barToken()` reads it on each access, so the
service writes the three tokens straight in and re-applies them whenever
`applyShellValues` rebuilds the map from scratch — which it does on every theme
switch and every `shell.toml` change.

The values stay in stock 12px-base units, exactly like the defaults, so
`barToken()` still multiplies them by `fontScale` and the two knobs compose:
`base-size` sets the overall shell scale, `iconScale` sets how much bigger than
that the icons sit. `icon-slot` grows by the canvas's absolute gain rather than
by the ratio, so the padding around each glyph stays as it was instead of the
bar spreading sideways.

An absent, unparseable or non-positive `iconScale`, or exactly `1`, hands the
tokens back rather than pinning them to today's defaults.

Same stow caveat as `dsrojo.suspend`: the plugin directory is a symlink and the
shell's watcher does not follow it, so run `omarchy-shell shell rescanPlugins`
(or `omarchy restart shell`) after editing `Service.qml`. Changes to
`bar.iconScale` in `shell.json` do hot-reload.
