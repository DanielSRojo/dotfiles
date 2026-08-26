#!/usr/bin/env python3
"""Give omarchy-shell pickers Ctrl+N/Ctrl+J (down) and Ctrl+P/Ctrl+K (up).

Those keys are not configurable upstream (basecamp/omarchy#7345 is still open),
and the packaged plugins under /usr/share/omarchy are pacman-owned. So each
listed plugin is cloned with `omarchy plugin clone` — which renames it to
<user>.<id> and keeps IPC routing via omarchy.clonedFrom — and the clone's key
chain is patched.

A clone pins that plugin at the version it was cloned from, so this script
re-clones from the current package and re-patches, and post-update.d runs it
after every `omarchy update`. Run it by hand any time; it is idempotent.

If the key chain ever moves and the patch no longer applies, the clone is
removed so the packaged plugin (arrow keys only) takes over, and a notification
says so — never leave a half-patched menu behind.
"""

import getpass
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

PLUGIN_IDS = ["menu", "clipboard"]
PLUGINS_DIR = Path.home() / ".config/omarchy/plugins"
MARK = "vim-style navigation (local addition)"
KEEP_BACKUPS = 2


def run(args, check=True):
    return subprocess.run(args, check=check, capture_output=True, text=True)


def notify(title, body):
    subprocess.run(
        ["omarchy-notification-send", "-u", "critical", "-g", "󰌌", title, body],
        check=False,
    )


def patch_qml(path: Path) -> bool:
    """Mirror the plugin's own Key_Down/Key_Up branches onto Ctrl+N/J and Ctrl+P/K."""
    src = path.read_text()
    if MARK in src:
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
        f"\n{ind}// {MARK}: Ctrl+N/Ctrl+J move down, Ctrl+P/Ctrl+K move up.\n"
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


def prune_backups(clone_id: str):
    """`omarchy plugin remove` leaves .<id>.bak.<stamp>/ behind on every run."""
    backups = sorted(PLUGINS_DIR.glob(f".{clone_id}.bak.*"))
    for old in backups[:-KEEP_BACKUPS] if len(backups) > KEEP_BACKUPS else []:
        shutil.rmtree(old, ignore_errors=True)
        print(f"  pruned stale backup {old.name}")


def main() -> int:
    # `omarchy plugin clone` talks to the running shell over IPC.
    if run(["omarchy-shell", "-q", "shell", "ping"], check=False).returncode != 0:
        notify("Vim nav not re-applied", "omarchy-shell is not running; run this hook by hand later.")
        print("omarchy-shell not responding; skipped", file=sys.stderr)
        return 0

    user = os.environ.get("USER") or getpass.getuser()
    touched, failed = [], []

    for plugin_id in PLUGIN_IDS:
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

        patched = [q.name for q in sorted(target.glob("*.qml")) if patch_qml(q)]
        if patched:
            touched.append(clone_id)
            print(f"  patched {', '.join(patched)}")
        else:
            # Fall back to the packaged plugin rather than ship a clone that
            # only pins an old version and adds nothing.
            run(["omarchy", "plugin", "remove", clone_id, "--yes"], check=False)
            failed.append(clone_id)
            print("  no Key_Down/Key_Up chain found; clone removed")

        prune_backups(clone_id)

    if touched:
        run(["omarchy", "restart", "shell"], check=False)
        print(f"restarted shell for: {', '.join(touched)}")

    if failed:
        notify(
            "Vim nav clones need attention",
            f"Could not patch: {', '.join(failed)}. Those pickers are back to arrow keys.",
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
