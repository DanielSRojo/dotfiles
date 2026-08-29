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

-- Open Steam's main window at the geometry a lone tiled window gets on this
-- monitor: floating, but filling the workspace inside the usual gap ring.
-- Hyprland has no gap-aware "maximize" rule (its `maximize` goes edge to edge,
-- ignoring gaps_out), and the Lua rule spec takes pixels, not percentages, so
-- the box is derived from the pieces below. Only the main window is matched --
-- ^Steam$ leaves the friends list and dialogs at their own sizes.
local BAR = 26 -- top edge reserved by the omarchy bar
local RING = 5 -- gaps_out (3) + border_size (2)
local MON = { w = 2560, h = 1440 } -- DP-1, see hypr/monitors.lua
o.window({ class = "^steam$", title = "^Steam$" }, {
  size = { MON.w - 2 * RING, MON.h - BAR - 2 * RING },
  move = { RING, BAR + RING },
})

-- Browsers open on workspace 1.
-- Classes verified on this machine: zen, chromium, brave-origin-nightly (the
-- nightly reports its own class, not brave-browser, so omarchy's browser tags
-- in default/hypr/apps/browser.lua miss it too). The rest are listed for
-- browsers not installed yet, and the capital variants for XWayland fallback.
-- Anchored on purpose: omarchy web apps carry classes like
-- chrome-<host>-Default, and those are separate apps that should keep opening
-- wherever they are launched from.
o.window(
  { class = "^([cC]hromium|[bB]rave-origin-nightly|[bB]rave-browser|zen|[fF]irefox|librewolf|(google-)?[cC]hrome|[vV]ivaldi-stable|[mM]icrosoft-edge)$" },
  { workspace = "1" }
)

-- Tag the Brave nightly as a chromium-based browser. Omarchy's tagging in
-- default/hypr/apps/browser.lua matches [bB]rave-browser, which this build's
-- class is not, so it never picked up the tile and opacity rules that tag
-- carries. Tagging late still works: Hyprland re-runs the tag-matching rules,
-- so omarchy's earlier consumers see this tag.
o.window({ class = "^[bB]rave-origin-nightly$" }, { tag = "+chromium-based-browser" })

-- Trastea (my iced app): always float, centered, at 1920x1080 on this 2560x1440
-- monitor. Matched by title, not class: iced 0.14 never populates
-- window::settings::PlatformSpecific.application_id (nothing in the crate maps
-- Settings::id onto it), so winit calls xdg_toplevel.set_app_id("") and
-- Hyprland reports an empty class. The title is set statically by
-- .title("Trastea") in src/main.rs, so it is the only stable handle today.
-- The optional class group keeps this rule working if I later set
-- application_id = "trastea" in the app.
o.window({ class = "^(trastea)?$", title = "^Trastea$" }, {
  float = true,
  size = { 1920, 1080 },
  center = true,
})
