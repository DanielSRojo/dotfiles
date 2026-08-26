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

-- Move between desktops, optionally carrying the active window along.
--
-- Neither direction uses a selector, because none of them behaves like an axis.
-- e-1/e+1 ring over the desktops that exist rather than running out at the ends:
-- with 1, 2 and 5 open, e-1 from 1 lands on 5 and e+1 from 5 lands on 1, which is
-- why , read as "forward" from desktop 1. Plain +1/-1 do stop at the ends, but
-- they walk the numbers instead of the desktops -- with a browser on 1 and Steam
-- on 3, +1 from 1 lands on an empty 2 instead of on Steam, and held down it keeps
-- spawning empties.
--
-- So the axis is a set of pickers over the non-empty desktops, which SUPER rides
-- to move focus:
--   .  the next desktop above, or one past the last of them if there is none
--   ,  the nearest desktop below, or nowhere if there is none
-- Forward is the only direction that opens a desktop, and it opens exactly one:
-- standing on the fresh desktop it made, last_used + 1 is where you already are,
-- so the key stops rather than trailing empties behind it.
--
-- SUPER + ALT rides the same pickers except backwards, where it goes to exactly
-- one desktop below instead. Skipping empties is right for focus, which has
-- nothing to do on an empty desktop, and wrong for a window, which fills the
-- desktop it lands on: pushing a window off 3 should put it on 2, not throw it
-- down to 1 because 2 happens to be empty at that moment.

-- Skip the special workspace (negative id) and any empty one, so a desktop that
-- was opened and then vacated does not extend the axis.
local function on_axis_workspace(workspace)
  return not workspace.special and workspace.id >= 1 and not workspace.is_empty
end

local function active_workspace_id()
  local current = hl.get_active_workspace()
  return current and current.id or 1
end

local function next_workspace_id()
  local current_id = active_workspace_id()
  local next_id, last_used = nil, 0

  for _, workspace in ipairs(hl.get_workspaces()) do
    if on_axis_workspace(workspace) then
      if workspace.id > last_used then
        last_used = workspace.id
      end
      if workspace.id > current_id and (next_id == nil or workspace.id < next_id) then
        next_id = workspace.id
      end
    end
  end

  local target = next_id or last_used + 1
  if target > current_id then
    return target
  end
end

local function previous_workspace_id()
  local current_id = active_workspace_id()
  local prev_id = nil

  for _, workspace in ipairs(hl.get_workspaces()) do
    if on_axis_workspace(workspace) then
      if workspace.id < current_id and (prev_id == nil or workspace.id > prev_id) then
        prev_id = workspace.id
      end
    end
  end

  return prev_id
end

-- Carrying a window backward is positional rather than a step along the axis, so
-- it lands on an empty desktop instead of skipping it. Ids start at 1, so from
-- desktop 1 there is nowhere below to put the window.
local function workspace_id_below()
  local target = active_workspace_id() - 1
  if target >= 1 then
    return target
  end
end

-- Turn a picker into a binding action. A picker returning nil means there is no
-- desktop that way, and the key does nothing.
local function to_workspace(pick, dispatcher)
  return function()
    local id = pick()
    if id then
      hl.dispatch(dispatcher({ workspace = tostring(id) }))
    end
  end
end

o.bind("SUPER + comma", "Previous workspace", to_workspace(previous_workspace_id, hl.dsp.focus))
o.bind("SUPER + period", "Next workspace, opening one past the last",
  to_workspace(next_workspace_id, hl.dsp.focus))
o.bind("SUPER + ALT + comma", "Move window to the workspace below",
  to_workspace(workspace_id_below, hl.dsp.window.move))
o.bind("SUPER + ALT + period", "Move window to next workspace, opening one past the last",
  to_workspace(next_workspace_id, hl.dsp.window.move))

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

-- Close window moves to SUPER + Q
hl.unbind("SUPER + W") -- was: Close window
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- Clipboard manager off CTRL, which SUPER + CTRL + hjkl and the cheatsheets
-- already crowd, and onto the ALT column.
hl.unbind("SUPER + CTRL + V") -- was: Clipboard manager
o.bind("SUPER + ALT + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")
