-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- HKC G2721P. Its EDID advertises 60Hz as the preferred timing, so "preferred"
-- silently caps the panel at 60Hz; pin the mode explicitly. The panel also
-- advertises 200/180Hz, but its DPCD reports DP 1.2 / 5.4Gbps, which is not
-- enough bandwidth for 2560x1440 above ~144Hz at 8bpc RGB.
--
-- vrr needs an EDID override to work at all: the panel declares its 48-200Hz
-- range descriptor as "default GTF" instead of "Range Limits Only", which
-- amdgpu's DisplayPort FreeSync path rejects, leaving vrr_capable=0. Patched
-- EDID is installed system-wide via /etc/modprobe.d/drm-edid-g2721p.conf --
-- see that file for the full explanation and how to remove it once the kernel
-- fix (Tomasz Pakula's "drm/amd: VRR fixes" series) ships.
hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1, vrr = 1 })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
