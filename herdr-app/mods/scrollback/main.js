// "scrollback.edit": open the focused terminal's whole history in $EDITOR
// (nvim) in a dialog, like zellij's edit-scrollback; the same key again closes
// it. Quitting the editor closes the dialog. Runs in a hidden host block so key
// commands reach it. An opencode pane has no terminal history (it draws on the
// alternate screen), so its session is exported as Markdown instead.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import * as fs from "fs/promises";
import { exec, focused, hc, home, terminals, openOverlay, closeOverlay, nextCommand, props, shared, setShared, theme, appHome } from "herdr";

const LINES = 100000;
const EDITOR = "nvim";
const SIZE = { width: 0.85, height: 0.85 }; // px, or up to 1: a share of the window
const OPEN = "scrollback.open";

// The scratch mod's dialog takes the keyboard while open, but focused() still
// names the pane under it: then read this tab's scratch shell instead.
const SCRATCH_OPEN = "scratch.window";
const SCRATCH_LABEL = "scratch.tab";

function sourceTerminal() {
  const at = focused();
  if (!at) return null;
  if (shared(SCRATCH_OPEN)) {
    const scratch = terminals().find((t) => {
      const tab = t.labels?.[SCRATCH_LABEL];
      const slash = t.address.indexOf("/");
      return t.state === "live" && tab && (slash < 0 ? tab : `${t.address.slice(0, slash)}/${tab}`) === at.tab;
    });
    if (scratch) return scratch.address;
  }
  return at.terminal;
}

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

// opencode draws on the alternate screen, so the terminal has no history of it.
// The terminal reports its session id (records), so export that session instead.
const TOOL_LINES = 40;

function opencodeSession(address) {
  const t = terminals().find((x) => x.address === address);
  const sessions = Object.entries(t?.records ?? {}).filter(([id, r]) => r?.app === "opencode" && id.startsWith("ses_"));
  if (!sessions.length) return null;
  const title = t.status?.title ?? t.report?.title;
  const [id] = sessions.find(([, r]) => r.title === title) ?? sessions.at(-1);
  return { id, cwd: t.foreground?.cwd ?? t.cwd ?? home() };
}

const clip = (text, max) => {
  const lines = String(text).replace(/\s+$/, "").split("\n");
  return lines.length > max ? [...lines.slice(0, max), `… ${lines.length - max} more lines`].join("\n") : lines.join("\n");
};

function transcript(data) {
  const out = [`# ${data.info?.title ?? "opencode session"}`, ""];
  for (const m of data.messages ?? []) {
    if (m.type === "user") {
      out.push("## User", "", String(m.text ?? "").trim(), "");
      for (const f of m.files ?? []) out.push(`- ${f.name ?? f.path ?? f.uri ?? f.url ?? JSON.stringify(f)}`);
      if (m.files?.length) out.push("");
    } else if (m.type === "assistant") {
      out.push("## Assistant", "");
      for (const p of m.content ?? []) {
        if (p.type === "text") out.push(p.text.trim(), "");
        else if (p.type === "reasoning" && p.text?.trim()) out.push(...p.text.trim().split("\n").map((l) => `> ${l}`), "");
        else if (p.type === "tool") {
          const s = p.state ?? {};
          out.push(`### ${p.name}${s.status === "error" ? " (failed)" : ""}`, "", "~~~", clip(JSON.stringify(s.input ?? {}), 10), "~~~", "");
          const body = s.status === "error"
            ? (s.error?.message ?? JSON.stringify(s.error))
            : (s.content ?? []).map((c) => (c.type === "text" ? c.text : `[${c.type}]`)).join("\n");
          if (body.trim()) out.push("~~~", clip(body, TOOL_LINES), "~~~", "");
        }
      }
    }
  }
  return out.join("\n") + "\n";
}

async function edit(cx) {
  const open = shared(OPEN);
  if (open) {
    setShared(OPEN, null);
    closeOverlay(open);
    return;
  }
  const source = sourceTerminal();
  if (!source) return;
  // In the mod's data folder: fs only writes under the app's home, and the
  // mod folder is a link out of it, so a path through it is refused.
  const dir = `${appHome()}/data/scrollback`;
  await fs.mkdir(dir, { recursive: true });
  let exported = null;
  const session = opencodeSession(source);
  if (session) {
    const r = await exec("opencode", ["session", "export", session.id], { cwd: session.cwd }).catch((e) => ({ code: -1, stderr: String(e.message || e) }));
    try {
      if (r.code !== 0) throw new Error(r.stderr.trim() || `opencode exited ${r.code}`);
      exported = transcript(JSON.parse(r.stdout));
    } catch (e) {
      console.log(`scrollback: opencode export failed, showing the screen: ${e.message}`);
    }
  }
  const file = `${dir}/history-${Date.now()}.${exported ? "md" : "txt"}`;
  const screen = exported ?? await read(source, 0);
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

  if (exported) return;
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
        const command = await nextCommand();
        // Throws in a build replaced by a hot reload, so only the live one acts.
        cx.notify();
        if (command === "edit") await edit(cx).catch((e) => console.log(`scrollback: ${e.message}`));
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
