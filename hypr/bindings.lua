-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- ---------------------------------------------------------------------------
-- Vi motions
--
--   h j k l  -> direction within the current desktop
--   , .      -> the desktop axis (previous / next)
--
--   SUPER            focus / switch
--   SUPER + ALT      take the active window with you
--
-- Omarchy's arrow bindings are left in place, so both sets work.
-- ---------------------------------------------------------------------------

-- Displaced by SUPER + h/j/k/l. Rebound below with the same letter plus an
-- extra modifier.
hl.unbind("SUPER + J") -- was: Toggle window split
hl.unbind("SUPER + K") -- was: Keybindings
hl.unbind("SUPER + L") -- was: Toggle workspace layout

o.bind("SUPER + CTRL + ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + CTRL + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- SUPER + ALT + K and SUPER + CTRL + K also held keybinding cheatsheets.
-- The app-specific ones move to SUPER + SHIFT + CTRL + <initial>.
hl.unbind("SUPER + ALT + K")  -- was: Tmux keybindings
hl.unbind("SUPER + CTRL + K") -- was: Herdr keybindings

o.bind("SUPER + CTRL + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + SHIFT + CTRL + T", "Tmux keybindings", "omarchy-menu-tmux-keybindings")
o.bind("SUPER + SHIFT + CTRL + H", "Herdr keybindings", "omarchy-menu-herdr-keybindings")

-- Displaced by SUPER + CTRL + h/l (grouped window focus).
hl.unbind("SUPER + CTRL + H") -- was: Hardware menu
hl.unbind("SUPER + CTRL + L") -- was: Lock system

o.bind("SUPER + CTRL + ALT + Y", "Hardware menu", "omarchy-menu toggle hardware")
o.bind("SUPER + CTRL + ALT + X", "Lock system", "omarchy-system-lock")

-- Displaced by SUPER + , and SUPER + ALT + , (the desktop axis). The rest of
-- the notification family keeps its comma chords.
-- xkbcommon names the keysyms "comma" and "period", not "COMMA"/"PERIOD".
hl.unbind("SUPER + comma")       -- was: Dismiss last notification
hl.unbind("SUPER + ALT + comma") -- was: Invoke last notification

o.bind("SUPER + CTRL + ALT + comma", "Dismiss last notification", "omarchy-shell notifications dismissOne")
o.bind("SUPER + SHIFT + CTRL + comma", "Invoke last notification", "omarchy-shell notifications invokeLast")

-- Focus window
o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- Reorder the active window within the current desktop
o.bind("SUPER + ALT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + ALT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + ALT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + ALT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

-- Move between desktops, optionally carrying the active window along
o.bind("SUPER + comma", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + period", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + ALT + comma", "Move window to previous workspace", hl.dsp.window.move({ workspace = "e-1" }))
o.bind("SUPER + ALT + period", "Move window to next workspace", hl.dsp.window.move({ workspace = "e+1" }))

-- Swap window (same action as SUPER + ALT + hjkl above, kept as a second home)
o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

-- Move the whole workspace to another monitor
o.bind("SUPER + SHIFT + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + J", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))
o.bind("SUPER + SHIFT + ALT + K", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
o.bind("SUPER + SHIFT + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))

-- Cycle focus inside a window group
o.bind("SUPER + CTRL + H", "Move grouped window focus left", hl.dsp.group.prev())
o.bind("SUPER + CTRL + L", "Move grouped window focus right", hl.dsp.group.next())

-- Send the active window to a numbered desktop. SUPER + ALT follows it, in
-- line with SUPER + ALT + hjkl / , / . above; SUPER + SHIFT stays put.
-- Digits are keycodes: code:10 is "1" ... code:18 is "9", code:19 is "0".

-- Displaced by SUPER + ALT + 1..5.
for index = 1, 5 do
  local key = "code:" .. tostring(index + 9)
  hl.unbind("SUPER + ALT + " .. key) -- was: Switch to group window N
  o.bind("SUPER + CTRL + ALT + " .. key, "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + SHIFT + " .. key) -- was: Move window to workspace N (following)
  o.bind("SUPER + SHIFT + " .. key, "Move window silently to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
  o.bind("SUPER + ALT + " .. key, "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) }))
end

-- Cycle keyboard layout (us,es -- set in hypr/input.lua). This keyboard has no
-- right Alt, so Omarchy's grp:alts_toggle is unreachable; a keybinding is used
-- instead of a bare xkb chord because every bare Alt+Shift variant also fires
-- on the 35 Omarchy bindings that hold Alt and Shift together.
o.bind("ALT + SHIFT + SPACE", "Cycle keyboard layout", "hyprctl switchxkblayout all next")
