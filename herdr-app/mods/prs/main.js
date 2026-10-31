// My open pull requests across GitHub, from the gh CLI.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, theme, layout, window } from "herdr";

function openUrl(url) {
  const platform = window()?.platform;
  if (platform === "macos") return exec("open", [url]);
  if (platform === "windows") return exec("cmd", ["/c", "start", "", url]);
  return exec("xdg-open", [url]);
}

const REFRESH_MS = 120000;
const PR_FIELDS = `nodes { ... on PullRequest {
      number title url isDraft updatedAt reviewDecision
      author { login }
      repository { name nameWithOwner }
      commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
    } }`;
const QUERY = `query {
  review: search(query: "is:pr is:open review-requested:@me archived:false sort:updated-desc", type: ISSUE, first: 50) { ${PR_FIELDS} }
  mine: search(query: "is:pr is:open author:@me archived:false sort:updated-desc", type: ISSUE, first: 50) { ${PR_FIELDS} }
}`;
const SECTIONS = [
  { id: "review", label: "Review requested" },
  { id: "mine", label: "Mine" },
];

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

function age(iso) {
  const m = Math.floor((Date.now() - Date.parse(iso)) / 60000);
  if (m < 60) return `${Math.max(m, 1)}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

const checksOf = (pr) => pr.commits?.nodes?.[0]?.commit?.statusCheckRollup?.state ?? null;

export default class Prs extends View {
  init(_props, cx) {
    this.prs = { review: [], mine: [] };
    this.error = null;
    this.loading = false;
    this.folded = new Set();
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
    this.refresh(cx);
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const r = await exec("gh", ["api", "graphql", "-f", `query=${QUERY}`]);
        if (r.code !== 0) throw new Error(r.stderr.trim() || `gh exited ${r.code}`);
        const data = JSON.parse(r.stdout).data;
        this.prs = Object.fromEntries(SECTIONS.map((s) => [s.id, data[s.id].nodes.filter((n) => n.number)]));
        this.error = null;
      } catch (e) {
        this.error = String(e.message ?? e);
      }
      this.loading = false;
      cx.notify();
    });
  }

  checks(t, state) {
    if (state === "PENDING" || state === "EXPECTED") return svg("mods/workspace-chrome/spinner.svg").size(11).flex_none().text_color(t.working).spin(900);
    const color = state === "SUCCESS" ? t.done : state === "FAILURE" || state === "ERROR" ? t.blocked : null;
    if (!color) return div().size(7).mx(2).flex_none();
    return div().size(7).mx(2).flex_none().rounded(4).bg(color);
  }

  review(t, decision) {
    const badge = { APPROVED: ["Approved", t.done], CHANGES_REQUESTED: ["Changes", t.blocked] }[decision];
    if (!badge) return null;
    return div().flex_none().px(5).h(16).rounded(4).bg(badge[1] + "26").text_size(10).font_semibold().text_color(badge[1]).flex().items_center().child(badge[0]);
  }

  row(t, pr, section) {
    const decision = this.review(t, pr.reviewDecision);
    return v_flex()
      .id(`pr-${pr.url}`)
      .px(8)
      .py(5)
      .flex_none()
      .rounded(8)
      .gap(2)
      .cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .tooltip(pr.url)
      .on_click(() => openUrl(pr.url))
      .child(h_flex().gap(7).items_center()
        .child(this.checks(t, checksOf(pr)))
        .child(div().flex_1().min_w(0).truncate().text_color(pr.isDraft ? t.muted : t.foreground).child(pr.title)))
      .child(h_flex().pl(18).gap(6).items_center().text_size(11).text_color(t.dim)
        .child(div().flex_none().child(`#${pr.number}`))
        .when(section === "review", (el) => el.child(div().min_w(0).truncate().child(pr.author?.login ?? "")))
        .when(pr.isDraft, (el) => el.child(div().flex_none().child("draft")))
        .child(div().flex_1())
        .when(Boolean(decision), (el) => el.child(decision))
        .child(div().flex_none().child(age(pr.updatedAt))));
  }

  header(t, key, label, count, top = false) {
    const open = !this.folded.has(key);
    return h_flex()
      .id(`fold-${key}`)
      .px(8)
      .pt(8)
      .h(top ? 30 : 26)
      .flex_none()
      .gap(6)
      .items_center()
      .text_size(11)
      .font_medium()
      .text_color(top ? t.muted : t.dim)
      .when(top, (el) => el.font_semibold())
      .cursor_pointer()
      .hover((s) => s.text_color(t.foreground))
      .on_click((_e, cx) => {
        open ? this.folded.add(key) : this.folded.delete(key);
        cx.notify();
      })
      .child(div().truncate().child(label))
      .child(div().text_color(t.dim).child(String(count)))
      .child(div().flex_1())
      .when(!open, (el) => el.child(svg("mods/workspace-chrome/chevron-right.svg").size(11).flex_none()));
  }

  render(cx) {
    const t = theme();
    const total = SECTIONS.reduce((n, s) => n + this.prs[s.id].length, 0);
    if (narrow()) {
      return v_flex().size_full().bg(t.chrome).border_t(1).border_color(t.border).items_center().pt(10).gap(4)
        .child(svg("mods/workspace-chrome/git-compare.svg").size(14).text_color(t.dim))
        .child(div().text_size(11).text_color(t.muted).child(String(total)));
    }

    const rows = SECTIONS.filter((s) => this.prs[s.id].length > 0).flatMap((s) => {
      const prs = this.prs[s.id];
      if (this.folded.has(s.id)) return [this.header(t, s.id, s.label, prs.length, true)];
      const byRepo = new Map();
      for (const pr of prs) byRepo.set(pr.repository.name, [...(byRepo.get(pr.repository.name) ?? []), pr]);
      return [
        this.header(t, s.id, s.label, prs.length, true),
        ...[...byRepo].flatMap(([repo, repoPrs]) => {
          const key = `${s.id}/${repo}`;
          return [this.header(t, key, repo, repoPrs.length), ...(this.folded.has(key) ? [] : repoPrs.map((pr) => this.row(t, pr, s.id)))];
        }),
      ];
    });

    return v_flex()
      .size_full()
      .min_h(0)
      .bg(t.chrome)
      .border_t(1)
      .border_color(t.border)
      .text_size(13)
      .child(h_flex().px(16).h(41).pt(14).pb(5).flex_none().items_center().justify_between()
        .child(h_flex().gap(6).items_center()
          .child(div().text_size(11.5).font_medium().text_color(t.dim).child("Pull requests"))
          .when(total > 0, (el) => el.child(div().text_size(11).text_color(t.dim).child(String(total)))))
        .child(div()
          .id("prs-refresh")
          .text_color(t.dim)
          .hover((s) => s.text_color(t.foreground))
          .tooltip("Refresh")
          .on_click((_e, cx) => this.refresh(cx))
          .child(this.loading
            ? svg("mods/workspace-chrome/spinner.svg").size(13).spin(900)
            : svg("mods/workspace-chrome/clock.svg").size(13))))
      .when(Boolean(this.error), (el) => el.child(div().px(16).pb(6).text_size(11.5).text_color(t.blocked).child(this.error)))
      .when(!this.error && !this.loading && total === 0, (el) => el.child(div().px(16).text_size(12).text_color(t.dim).child("No open pull requests.")))
      .child(v_flex().id("prs-list").flex_1().min_h(0).px(8).pb(8).overflow_y_scrollbar().children(rows));
  }
}
