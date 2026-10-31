// A scratch shell in a dialog, toggled by "scratch.toggle" (alt-f): it takes the
// keyboard when it opens; a click beside it hides it (the shell keeps running).
// An overlay lives only as long as the mod copy that opened it, so a hidden host
// block in the layout owns it; inside the dialog, the same mod draws the title bar.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { hc, home, terminals, openOverlay, closeOverlay, nextCommand, props, shared, setShared, theme } from "herdr";

const NAME = "scratch";
const OPEN = "scratch.window";

async function scratchTerminal() {
  const live = terminals().find((t) => t.name === NAME && t.state === "live");
  if (live) return live.address;
  const r = await hc(["run", "--json", "--bg", "--keep", "--no-parent", "--name", NAME, "--cwd", home()]);
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
  openWindow(await scratchTerminal());
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
