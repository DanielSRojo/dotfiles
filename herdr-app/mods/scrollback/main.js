// "scrollback.edit": open the focused terminal's whole history in $EDITOR
// (nvim) in a dialog, like zellij's edit-scrollback; the same key again closes
// it. Quitting the editor closes the dialog. Runs in a hidden host block so key
// commands reach it.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import * as fs from "fs/promises";
import { exec, focused, hc, home, openOverlay, closeOverlay, nextCommand, props, shared, setShared, theme, appHome } from "herdr";

const LINES = 100000;
const EDITOR = "nvim";
const SIZE = { width: 0.85, height: 0.85 }; // px, or up to 1: a share of the window
const OPEN = "scrollback.open";

// The editor's terminal starts at hc's default size (120x200); nvim started
// before the dialog resizes it draws a blank screen, so wait for that resize.
// It listens on a socket so the full history can be loaded into it later.
const SCRIPT = `[ "$(stty size)" = "120 200" ] && { trap : WINCH; sleep 2 & wait $!; kill $! 2>/dev/null; }; ${EDITOR} --listen "$1.sock" + "$1"; rm -f "$1" "$1.sock"`;

// Put the older lines (from file _A[1]) above what the editor shows, keeping
// the cursor, view and any selection on the same text. With _A[2] = 1 the file
// is the whole history instead, for when the screen changed meanwhile.
const LOAD = `(function(a)
  if vim.b.scrollback_full then return 1 end
  local lines, whole, edited = vim.fn.readfile(a[1]), a[2] == 1, vim.bo.modified
  local view = vim.fn.winsaveview()
  local shift = whole and #lines - vim.fn.line("$") or #lines
  vim.api.nvim_buf_set_lines(0, 0, whole and -1 or 0, false, lines)
  view.lnum = math.max(1, view.lnum + shift)
  view.topline = math.max(1, view.topline + shift)
  vim.fn.winrestview(view)
  if not edited then vim.bo.modified = false end
  vim.b.scrollback_full = true
  return 1
end)(_A)`;

const sleep = (cx, ms) => new Promise((done) => cx.timer.after(ms, () => done()));

// The screen alone is always quick; with history (lines), hc read of an agent
// can take seconds.
async function read(source, lines) {
  const r = await hc(["read", source, "--lines", String(lines)]);
  if (r.code !== 0) throw new Error(r.stderr.trim() || `hc exited ${r.code}`);
  const out = r.stdout.split("\n").filter((l) => !l.startsWith("[hc]"));
  while (out.length && !out.at(-1).trim()) out.pop();
  return out.join("\n") + "\n";
}

async function edit(cx) {
  const open = shared(OPEN);
  if (open) {
    setShared(OPEN, null);
    closeOverlay(open);
    return;
  }
  const source = focused()?.terminal;
  if (!source) return;
  // A hidden file in this mod's folder (fs writes only under the app's home);
  // hidden files don't reload the mod.
  const file = `${appHome()}/mods/scrollback/.history-${Date.now()}.txt`;
  const screen = await read(source, 0);
  await fs.writeFile(file, screen);
  const r = await hc(["run", "--json", "--bg", "--no-parent", "--rm", "--name", `scrollback-${Date.now() % 1e6}`,
    "--cwd", home(), "--", "sh", "-c", SCRIPT, "sh", file]);
  if (r.code !== 0) throw new Error(r.stderr.trim() || `hc exited ${r.code}`);
  const address = JSON.parse(r.stdout).address;

  // The dialog closes itself when the editor exits.
  const id = openOverlay({
    kind: "dialog",
    modal: true,
    ...SIZE,
    layout: {
      type: "column",
      children: [
        { type: "block", size: { px: 30 }, content: { mod: "scrollback", props: { titlebar: true, source, address, file } } },
        { type: "block", content: { terminal: address } },
      ],
    },
  });
  setShared(OPEN, id);

  cx.spawn(async (cx) => {
    const full = await read(source, LINES);
    if (full === screen || shared(OPEN) !== id) return;
    const older = full.endsWith(screen);
    const extra = `${file}.older`;
    await fs.writeFile(extra, older ? full.slice(0, -screen.length) : full);
    // nvim may not be listening yet (it waits for the dialog's size): retry.
    const expr = `luaeval('${LOAD.replace(/\n\s*/g, " ")}', ['${extra}', ${older ? 0 : 1}])`;
    for (let i = 0; i < 25 && shared(OPEN) === id; i++) {
      const r = await exec(EDITOR, ["--server", `${file}.sock`, "--remote-expr", expr]).catch(() => null);
      if (r?.code === 0) break;
      await sleep(cx, 200);
    }
    await exec("rm", ["-f", extra]);
  });
}

export default class Scrollback extends View {
  init(_props, cx) {
    if (!props()?.host) return;
    setShared(OPEN, null);
    cx.spawn(async (cx) => {
      for (;;) {
        if ((await nextCommand()) === "edit") await edit(cx).catch((e) => console.log(`scrollback: ${e.message}`));
      }
    });
  }

  async close() {
    // Closing the dialog by hand ends the editor too.
    if (!props()?.titlebar) return;
    if (shared(OPEN) === props().overlay) setShared(OPEN, null);
    await exec("rm", ["-f", props().file, `${props().file}.sock`]);
    await hc(["kill", props().address]);
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
      .child(div().flex_1().text_color(t.muted).font_medium().child(`Scrollback of ${props().source}`))
      .child(div().text_size(11).text_color(t.dim).child(":q to close"))
      .child(div()
        .id("scrollback-close")
        .p(3)
        .rounded(4)
        .text_color(t.dim)
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click(() => closeOverlay(props().overlay))
        .child(svg("mods/workspace-chrome/x.svg").size(12)));
  }
}
