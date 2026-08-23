-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Center Steam's own windows.
-- Omarchy's default (default/hypr/apps/steam.lua) floats every steam window but
-- only centers the one titled exactly "Steam", so dialogs like "Sign in to Steam"
-- get no position rule and can land off-screen.
-- Anchored to ^steam$ so Proton game windows (steam_app_*) are untouched, and
-- notification toasts are excluded so they stay in their corner.
o.window({ class = "^steam$", title = "negative:^notificationtoasts" }, { center = true })

-- Always open Steam's own windows on workspace 3.
-- Same match as the centering rule above: ^steam$ keeps Proton game windows
-- (steam_app_*) on whatever workspace you launch them from, and toasts are
-- excluded so notifications aren't yanked to workspace 3.
-- focus_on_activate is on system-wide (omarchy default), and Steam sends an
-- xdg-activation request when its main window maps, which overrides "silent".
-- suppressevent activatefocus drops the focus half of that request.
-- "maximize" is re-stated because omarchy sets it globally for all windows.
o.window({ class = "^steam$", title = "negative:^notificationtoasts" },
  { workspace = "3 silent", suppress_event = "activatefocus maximize" })

-- Always open Steam games on workspace 4.
-- Proton/native game windows carry class steam_app_<appid>.
o.window({ class = "^steam_app_" }, { workspace = "4" })
