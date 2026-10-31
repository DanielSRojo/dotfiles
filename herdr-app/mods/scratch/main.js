// A scratch shell in a dialog, toggled by "scratch.toggle" (alt-f): it takes the
// keyboard when it opens; a click beside it hides it (the shell keeps running).
// Each tab has its own, started in the folder of the pane focused when it was
// first opened; it's ended once its tab is gone.
// An overlay lives only as long as the mod copy that opened it, so a hidden host
// block in the layout owns it; inside the dialog, the same mod draws the title bar.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { focused, hc, spaces, terminals, openOverlay, closeOverlay, nextCommand, props, shared, setShared, theme } from "herdr";

const NAME = "scratch";
const OPEN = "scratch.window";
const LABEL = "scratch.tab";

// Remote tab ids and terminal addresses carry a "machine/" prefix; labels on
// that machine don't.
const local = (id) => id.slice(id.indexOf("/") + 1);
const tabOf = (t) => {
  const tab = t.labels?.[LABEL];
  const slash = t.address.indexOf("/");
  return tab && (slash < 0 ? tab : `${t.address.slice(0, slash)}/${tab}`);
};

async function scratchTerminal() {
  const at = focused();
  if (!at) return null;
  const tabs = new Set(spaces().flatMap((s) => s.tabs.map((t) => t.id)));
  const scratches = terminals().filter((t) => t.state === "live" && tabOf(t));
  for (const t of scratches) if (!tabs.has(tabOf(t))) hc(["kill", t.address]);
  const live = scratches.find((t) => tabOf(t) === at.tab);
  if (live) return live.address;

  const machine = spaces().find((s) => s.id === at.space)?.machine;
  const args = ["run", "--json", "--bg", "--keep", "--no-parent", "--label", `${LABEL}=${local(at.tab)}`];
  if (at.cwd) args.push("--cwd", at.cwd);
  if (machine) args.push("--on", machine);
  const r = await hc(args);
  if (r.code !== 0) throw new Error(r.stderr.trim() || `hc exited ${r.code}`);
  return JSON.parse(r.stdout).address;
}

function openWindow(address) {
  const id = openOverlay({
    kind: "dialog",
    key: NAME,
    width: 0.6,
    height: 0.8,
    layout: {
      type: "column",
      children: [
        { type: "block", size: { px: 30 }, content: { mod: "scratch", props: { titlebar: true } } },
        { type: "block", content: { terminal: address } },
      ],
    },
  });
  setShared(OPEN, id);
}

async function toggle() {
  const open = shared(OPEN);
  if (open) {
    setShared(OPEN, null);
    closeOverlay(open);
    return;
  }
  const address = await scratchTerminal();
  if (address) openWindow(address);
}

export default class Scratch extends View {
  init(_props, cx) {
    if (!props()?.host) return;
    setShared(OPEN, null);
    cx.spawn(async () => {
      for (;;) {
        if ((await nextCommand()) === "toggle") await toggle();
      }
    });
  }

  async close() {
    if (props()?.titlebar && shared(OPEN) === props().overlay) setShared(OPEN, null);
  }

  render() {
    if (!props()?.titlebar) return div();
    const t = theme();
    return h_flex()
      .size_full()
      .px(12)
      .gap(8)
      .items_center()
      .bg(t.chrome)
      .border_b(1)
      .border_color(t.border)
      .text_size(12)
      .child(svg("mods/workspace-chrome/terminal.svg").size(13).flex_none().text_color(t.dim))
      .child(div().flex_1().text_color(t.muted).font_medium().child("Scratch"))
      .child(div().text_size(11).text_color(t.dim).child("⌥F"))
      .child(div()
        .id("scratch-hide")
        .p(3)
        .rounded(4)
        .text_color(t.dim)
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .tooltip("Hide (the shell keeps running)")
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click(() => closeOverlay(props().overlay))
        .child(svg("mods/workspace-chrome/x.svg").size(12)));
  }
}
