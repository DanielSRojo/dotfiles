// "nav.left" / "nav.right": go to the pane on that side of the shown tab, like
// pane.go; with no pane there, go on to the previous or next tab's last or
// first pane. A tab with a zoomed pane counts as that pane alone.
// Runs in a hidden host block so key commands reach it.

import { View, div } from "gpui-kit";
import { focused, nextCommand, panes, props, run, spaces } from "herdr";

const STEP = { left: -1, right: 1 };

function shownPanesOf(tab) {
  const all = panes().filter((p) => p.tab === tab);
  const zoomed = all.find((p) => p.zoomed);
  return zoomed ? [zoomed] : all;
}

async function movedSideways(direction, from, cx) {
  run("pane.go", { direction });
  // pane.go lands a frame or more after run() returns, and says nothing when
  // there is no pane that way, so wait a little for focus to move.
  for (let frame = 0; frame < 6; frame++) {
    if (focused()?.pane !== from) return true;
    await cx.sleep(16);
  }
  return focused()?.pane !== from;
}

function crossTab(at, by) {
  const tabs = (spaces().find((s) => s.id === at.space)?.tabs ?? []).filter((t) => !t.settled);
  const t = tabs.findIndex((tab) => tab.id === at.tab);
  if (t < 0 || tabs.length < 2) return;
  const target = tabs[(t + by + tabs.length) % tabs.length];
  const there = shownPanesOf(target.id);
  const land = by > 0 ? there[0] : there.at(-1);
  if (land) run("pane.focus", { pane: land.pane });
  else run("tab.select", { id: target.id });
}

async function step(direction, cx) {
  const at = focused();
  if (!at) return;
  const alone = shownPanesOf(at.tab).length < 2;
  if (at.pane && !alone && (await movedSideways(direction, at.pane, cx))) return;
  crossTab(at, STEP[direction]);
}

export default class Nav extends View {
  init(_props, cx) {
    if (!props()?.host) return;
    cx.spawn(async (cx) => {
      for (;;) {
        const direction = await nextCommand();
        // Throws in a build replaced by a hot reload, so only the live one acts.
        cx.notify();
        if (direction in STEP) await step(direction, cx);
      }
    });
  }

  render() {
    return div();
  }
}
