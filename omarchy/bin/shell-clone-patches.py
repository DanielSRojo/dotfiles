#!/usr/bin/env python3
"""Carry local patches to omarchy-shell plugins that only a clone can hold.

The packaged plugins under /usr/share/omarchy belong to the omarchy package, and
PluginRegistry.qml refuses a third-party plugin that shadows a first-party id, so
`omarchy plugin clone` (which renames to <user>.<id> and records
omarchy.clonedFrom) is the only seam. A clone pins its plugin at the version it
was taken from, so this script re-clones from the current package and re-applies
each patch; post-update.d runs it after every `omarchy update`.

Patches, one per plugin:
  menu, clipboard  Ctrl+N/Ctrl+J move down, Ctrl+P/Ctrl+K move up, mirroring the
                   plugin's own Qt.Key_Down / Qt.Key_Up bodies.
  idle             the idle "screensaver" step powers the displays off instead of
                   launching the screensaver. Waking is stock: on activity the
                   service runs omarchy-system-wake.

Each patch is idempotent and reports whether it applied. A patch that no longer
matches means upstream moved the code: the clone is dropped so the packaged
plugin takes over, and a notification names it.
"""

import getpass
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

PLUGINS_DIR = Path.home() / ".config/omarchy/plugins"
NAV_MARK = "vim-style navigation (local addition)"
DPMS_MARK = 'hl.dsp.dpms(\\"off\\")'
KEEP_BACKUPS = 2


def run(args, check=True):
    return subprocess.run(args, check=check, capture_output=True, text=True)


def notify(title, body):
    subprocess.run(
        ["omarchy-notification-send", "-u", "critical", "-g", "󰌌", title, body],
        check=False,
    )


def patch_nav(path: Path) -> bool:
    """Mirror the plugin's Key_Down/Key_Up branches onto Ctrl+N/J and Ctrl+P/K."""
    src = path.read_text()
    if NAV_MARK in src:
        return True

    def branch(key):
        return re.search(
            r"\n(?P<ind>[ \t]*)\} else if \(event\.key === Qt\.%s\) \{\n"
            r"(?P<body>(?:.*\n)*?)(?=[ \t]*\} else if)" % key,
            src,
        )

    down, up = branch("Key_Down"), branch("Key_Up")
    if not (down and up):
        return False

    ind = down.group("ind")
    add = (
        f"\n{ind}// {NAV_MARK}: Ctrl+N/Ctrl+J move down, Ctrl+P/Ctrl+K move up.\n"
        f"{ind}}} else if ((event.key === Qt.Key_N || event.key === Qt.Key_J)"
        f" && event.modifiers === Qt.ControlModifier) {{\n"
        f"{down.group('body').rstrip(chr(10))}\n"
        f"{ind}}} else if ((event.key === Qt.Key_P || event.key === Qt.Key_K)"
        f" && event.modifiers === Qt.ControlModifier) {{\n"
        f"{up.group('body').rstrip(chr(10))}"
    )
    at = down.end("body")
    path.write_text(src[:at].rstrip("\n") + add + "\n" + src[at:])
    return True


def patch_idle_dpms(path: Path) -> bool:
    """Blank the displays where the idle service would launch the screensaver.

    hyprctl dispatch evaluates its argument as Lua here (the hypr config is Lua),
    hence the hl.dsp call form. The isLocked guard in front of it is kept: when
    the session is already locked the lock plugin owns the screen.
    """
    src = path.read_text()
    if DPMS_MARK in src:
        return True
    if "omarchy-launch-screensaver" not in src:
        return False
    path.write_text(
        src.replace("omarchy-launch-screensaver", "hyprctl dispatch 'hl.dsp.dpms(\\\"off\\\")'")
    )
    return True


PLUGINS = [
    ("menu", patch_nav),
    ("clipboard", patch_nav),
    ("idle", patch_idle_dpms),
]


def settle(seconds: float = 4.0, quiet_for: float = 1.5):
    """Wait for the plugin-reload storm the patches above set off to finish.

    A reload logs nothing this script can read, so quiet is inferred from the
    shell answering ping without a reload in flight: ping is served on the same
    event loop that incubates components, so a prompt reply means it is idle.
    """
    deadline = time.monotonic() + seconds
    quiet_since = None
    while time.monotonic() < deadline:
        start = time.monotonic()
        ok = run(["omarchy-shell", "-q", "shell", "ping"], check=False).returncode == 0
        responsive = ok and (time.monotonic() - start) < 0.5
        if responsive:
            quiet_since = quiet_since or time.monotonic()
            if time.monotonic() - quiet_since >= quiet_for:
                return
        else:
            quiet_since = None
        time.sleep(0.25)


def prune_backups(clone_id: str):
    """`omarchy plugin remove` leaves .<id>.bak.<stamp>/ behind on every run."""
    backups = sorted(PLUGINS_DIR.glob(f".{clone_id}.bak.*"))
    for old in backups[:-KEEP_BACKUPS] if len(backups) > KEEP_BACKUPS else []:
        shutil.rmtree(old, ignore_errors=True)
        print(f"  pruned stale backup {old.name}")


def main() -> int:
    # `omarchy plugin clone` talks to the running shell over IPC.
    if run(["omarchy-shell", "-q", "shell", "ping"], check=False).returncode != 0:
        notify("Shell clone patches not applied", "omarchy-shell is not running; run this hook by hand later.")
        print("omarchy-shell not responding; skipped", file=sys.stderr)
        return 0

    user = os.environ.get("USER") or getpass.getuser()
    touched, failed = [], []

    for plugin_id, patch in PLUGINS:
        clone_id = f"{user}.{plugin_id}"
        target = PLUGINS_DIR / clone_id
        print(f"{clone_id}:")

        if target.exists():
            run(["omarchy", "plugin", "remove", clone_id, "--yes"], check=False)
        result = run(["omarchy", "plugin", "clone", f"omarchy.{plugin_id}"], check=False)
        if result.returncode != 0 or not target.is_dir():
            failed.append(clone_id)
            print(f"  clone failed: {result.stderr.strip() or result.stdout.strip()}")
            continue

        patched = [q.name for q in sorted(target.glob("*.qml")) if patch(q)]
        if patched:
            touched.append(clone_id)
            print(f"  patched {', '.join(patched)}")
        else:
            # Fall back to the packaged plugin rather than ship a clone that
            # only pins an old version and adds nothing.
            run(["omarchy", "plugin", "remove", clone_id, "--yes"], check=False)
            failed.append(clone_id)
            print("  patch no longer applies; clone removed")

        prune_backups(clone_id)

    if touched:
        # Every write above trips the shell's plugin watcher, and each reload
        # re-incubates the config asynchronously. Asking it to exit mid-flight
        # segfaults it in QQmlObjectCreator::finalize (crash 7kr1ttrfkt), so let
        # the reloads drain before requesting the restart the clones need.
        settle()
        run(["omarchy", "restart", "shell"], check=False)
        print(f"restarted shell for: {', '.join(touched)}")

    if failed:
        notify(
            "Shell clone patches need attention",
            f"Could not patch: {', '.join(failed)}. Those plugins are back to stock behaviour.",
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
