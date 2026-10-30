// "nav.left" / "nav.right": walk the panes of the shown tab in order; past the
// first or last one, go on to the previous or next tab's last or first pane.
// A tab with a zoomed pane counts as that pane alone.
// Runs in a hidden host block so key commands reach it.

import { View, div } from "gpui-kit";
import { focused, nextCommand, panes, props, run, spaces } from "herdr";

const STEP = { left: -1, right: 1 };

function shownPanesOf(tab) {
  const all = panes().filter((p) => p.tab === tab);
  const zoomed = all.find((p) => p.zoomed);
  return zoomed ? [zoomed] : all;
}

function step(by) {
  const at = focused();
  if (!at) return;
  const here = shownPanesOf(at.tab);
  const i = here.findIndex((p) => p.pane === at.pane);
  const next = here[i + by];
  if (i >= 0 && next) return run("pane.focus", { pane: next.pane });

  const tabs = (spaces().find((s) => s.id === at.space)?.tabs ?? []).filter((t) => !t.settled);
  const t = tabs.findIndex((tab) => tab.id === at.tab);
  if (t < 0 || tabs.length < 2) return;
  const target = tabs[(t + by + tabs.length) % tabs.length];
  const there = shownPanesOf(target.id);
  const land = by > 0 ? there[0] : there.at(-1);
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
