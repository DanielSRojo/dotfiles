// "nav.left" / "nav.right": walk the panes of the shown tab in order; past the
// first or last one, go on to the previous or next tab's last or first pane.
// Runs in a hidden host block so key commands reach it.

import { View, div } from "gpui-kit";
import { focused, nextCommand, panes, props, run, spaces } from "herdr";

const STEP = { left: -1, right: 1 };

const panesOf = (tab) => panes().filter((p) => p.tab === tab);

function moveWithinTab(from, to) {
  if (from.zoomed) run("pane.zoom", { pane: from.pane });
  run("pane.focus", { pane: to.pane });
  if (from.zoomed) run("pane.zoom", { pane: to.pane });
}

function step(by) {
  const at = focused();
  if (!at) return;
  const here = panesOf(at.tab);
  const i = here.findIndex((p) => p.pane === at.pane);
  const next = here[i + by];
  if (i >= 0 && next) return moveWithinTab(here[i], next);

  const tabs = (spaces().find((s) => s.id === at.space)?.tabs ?? []).filter((t) => !t.settled);
  const t = tabs.findIndex((tab) => tab.id === at.tab);
  if (t < 0 || tabs.length < 2) return;
  const target = tabs[(t + by + tabs.length) % tabs.length];
  const there = panesOf(target.id);
  const land = there.find((p) => p.zoomed) ?? (by > 0 ? there[0] : there.at(-1));
  if (land) run("pane.focus", { pane: land.pane });
  else run("tab.select", { id: target.id });
}

export default class Nav extends View {
  init(_props, cx) {
    if (!props()?.host) return;
    cx.spawn(async () => {
      for (;;) {
        const by = STEP[await nextCommand()];
        if (by) step(by);
      }
    });
  }

  render() {
    return div();
  }
}
