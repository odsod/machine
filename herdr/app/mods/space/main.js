// Start or close a space. Opened as a dialog with
// props { tab: "start" | "close" } or { confirm: true }; the prefix mod binds start and confirm.
//
// Start: pick a repo (then a bookmark), or a folder, and Enter. The type,
// machine and agent are remembered chips: ctrl+t, ctrl+m, ctrl+g cycle them.
// ctrl+l (or ctrl+h) toggles between Start and Close.
//
// Close: the machine's spaces, the current one first, then jj workspaces no
// space shows. Enter closes a space; when it shows a jj workspace, it also
// forgets the workspace and trashes its folder. Other folders stay.
// confirm: the same for the current space, as a small yes/no dialog.
//
// `herdr-space` (in `herdr/`) does the work on the chosen machine; this mod
// only draws lists and runs space.close. Start runs `herdr-space start` here,
// the same command agents use.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Input, InputState, ScrollHandle } from "gpui-base";
import {
  checking,
  closeOverlay,
  exec,
  focused,
  machines,
  notify,
  panes,
  props,
  run,
  spaces,
  theme,
} from "herdr";

const TYPES = ["Workspace", "Code", "Activity", "Project", "Vault"];
const AGENTS = ["claude", "codex", "agy", "pi"];
const MAX_ROWS = 200;
const PLACEHOLDERS = {
  first: "Type to filter",
  bookmark: "Filter bookmarks, or type a new name",
  linear: "Filter issues and projects",
  close: "Filter spaces",
};
const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

const ago = (epoch) => {
  const s = Math.max(0, Date.now() / 1000 - epoch);
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  if (s < 604800) return `${Math.floor(s / 86400)}d`;
  return `${Math.floor(s / 604800)}w`;
};

// Every word of the query appears in the text, in any order.
const matches = (query, text) => {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  const hay = text.toLowerCase();
  return words.every((w) => hay.includes(w));
};

const under = (path, dir) => Boolean(path) && (path === dir || path.startsWith(dir + "/"));

async function helper(args, on, timeout = 60_000) {
  let r;
  try {
    r = await exec("herdr-space", args, { on: on ?? null, timeout });
  } catch (error) {
    throw new Error(
      `herdr-space did not start${on ? ` on ${on}` : ""}: ${error}. Run mise run apply there.`,
    );
  }
  if (r.code !== 0) throw new Error(r.stderr.trim() || `herdr-space ${args[0]} failed`);
  return JSON.parse(r.stdout || "null");
}

export default class Space extends View {
  init(_props, cx) {
    // confirm: close the current space (and its jj workspace) after one Enter.
    this.confirm = Boolean(props()?.confirm);
    this.tab = this.confirm || props()?.tab === "close" ? "close" : "start";
    this.type = Math.max(0, TYPES.indexOf(localStorage.getItem("type")));
    this.agent = Math.max(0, AGENTS.indexOf(localStorage.getItem("agent")));
    this.localName = "this computer";
    this.machine =
      this.tab === "close"
        ? (this.currentSpace()?.machine ?? null)
        : localStorage.getItem("machine") || null;
    if (!this.machineList().includes(this.machine)) this.machine = null;
    this.step = "first"; // start: "first" | "bookmark" | "linear"
    this.repo = null; // the repo picked for Workspace
    this.cache = {}; // "<machine>|<what>" -> list, or an Error
    this.linear = undefined;
    this.at = 0;
    this.marks = new Set();
    this.busy = false;
    this.error = "";
    this.queries = {};
    this.scroll = ScrollHandle.new();
    // One input per list, for its placeholder; `this.input` is the shown one.
    this.inputs = {};
    for (const [field, placeholder] of Object.entries(PLACEHOLDERS)) {
      this.inputs[field] = InputState.new({ value: "", placeholder });
      this.inputs[field].on("change", (_e, cx) => {
        this.at = 0;
        this.error = "";
        cx.notify();
      });
    }
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(100, () => this.input.focus());
    if (checking()) return;
    cx.spawn(async (cx) => {
      const r = await exec("hostname", ["-s"]).catch(() => null);
      if (r?.code === 0 && r.stdout.trim()) this.localName = r.stdout.trim();
      cx.notify();
    });
    this.load(cx);
  }

  get input() {
    return this.inputs[this.tab === "close" ? "close" : this.step];
  }

  // --- Data ---

  machineList() {
    return [
      null,
      ...machines()
        .map((m) => m.name)
        .filter(Boolean),
    ];
  }

  machineLabel(m) {
    return m ?? this.localName;
  }

  currentSpace() {
    const f = focused();
    return spaces().find((s) => s.id === f?.space) ?? spaces().find((s) => s.active);
  }

  // What the visible list needs, read once per machine and kept.
  want() {
    if (this.tab === "close") return ["workspaces", ["workspaces"]];
    if (this.step === "bookmark") return [`bookmarks:${this.repo}`, ["bookmarks", this.repo]];
    if (this.step === "linear") return null;
    const type = TYPES[this.type];
    if (type === "Workspace" || type === "Code") return ["repos", ["repos"]];
    return [`dirs:${type}`, ["dirs", type.toLowerCase()]];
  }

  load(cx, fresh = false) {
    const want = this.want();
    if (!want) return;
    const [what, args] = want;
    const key = `${this.machine ?? ""}|${what}`;
    if (!fresh && key in this.cache) return;
    if (!(key in this.cache)) this.cache[key] = undefined;
    const on = this.machine;
    cx.spawn(async (cx) => {
      try {
        this.cache[key] = await helper(args, on);
      } catch (error) {
        this.cache[key] = error;
      }
      cx.notify();
    });
  }

  data() {
    const want = this.want();
    return want ? this.cache[`${this.machine ?? ""}|${want[0]}`] : this.linear;
  }

  // The jj workspace a space shows: its folder or a pane's live folder.
  spacesAt(path) {
    const all = panes();
    return spaces().filter((s) => {
      if ((s.machine ?? null) !== (this.machine ?? null)) return false;
      if (under(s.folder, path)) return true;
      const tabs = new Set(s.tabs.map((t) => t.id));
      return all.some((p) => tabs.has(p.tab) && under(p.cwd, path));
    });
  }

  // Close: the machine's spaces, the current one first, each with the jj
  // workspace it shows if any; then jj workspaces no space shows.
  closeRows() {
    const data = this.data();
    const wss = Array.isArray(data) ? data : [];
    const cur = this.currentSpace();
    const mine = spaces().filter((s) => (s.machine ?? null) === (this.machine ?? null));
    mine.sort((a, b) => (b.id === cur?.id) - (a.id === cur?.id));
    const rows = mine.map((s) => {
      const ws = wss.find((w) => this.spacesAt(w.path).some((x) => x.id === s.id));
      return {
        key: `space:${s.id}`,
        label: s.name,
        state: ws ? "jj workspace" : data === undefined ? "…" : "space",
        current: s.id === cur?.id,
        space: s,
        ws,
      };
    });
    for (const w of wss) {
      if (this.spacesAt(w.path).length) continue;
      rows.push({
        key: w.path,
        label: `${w.repo.split("/").pop()}/${w.name}`,
        state: "not open",
        right: ago(w.epoch),
        tone: w.changes.length ? "working" : "muted",
        ws: w,
      });
    }
    return rows;
  }

  // The visible list as rows { key, label, right, tone, item, create }.
  rows() {
    const q = this.input.value().trim();
    if (this.tab === "close") return this.closeRows().filter((r) => matches(q, r.label));
    const data = this.data();
    if (!Array.isArray(data)) return [];
    let rows;
    if (this.step === "linear") {
      rows = data.map((l) => ({ key: `${l.kind}:${l.id}`, label: l.label, item: l }));
    } else if (this.step === "bookmark") {
      rows = data.map((b) => ({
        key: b.name + (b.remote ? "@origin" : ""),
        label: b.name + (b.remote ? "@origin" : ""),
        right: ago(b.epoch),
        tone: b.remote ? "muted" : null,
        item: b,
      }));
    } else if (data[0]?.repo !== undefined) {
      rows = data.map((r) => ({ key: r.repo, label: r.repo, split: true, item: r }));
    } else {
      rows = data.map((d) => ({ key: d.name, label: d.name, right: ago(d.epoch), item: d }));
    }
    rows = rows.filter((r) => matches(q, r.label));
    const creates =
      this.tab === "start" &&
      (this.step === "bookmark" || ["Activity", "Project"].includes(TYPES[this.type]));
    if (creates && q && !rows.some((r) => r.label === q || r.label === `${q}@origin`)) {
      rows.unshift({ key: `new:${q}`, label: `new: ${q}`, tone: "muted", create: q });
    }
    return rows.slice(0, MAX_ROWS);
  }

  // --- Actions ---

  close() {
    closeOverlay(props().overlay);
  }

  setQuery(value) {
    this.input.set_value(value);
    this.at = 0;
  }

  go(step, cx) {
    this.queries[this.step] = this.input.value();
    this.step = step;
    this.marks.clear();
    this.setQuery(this.queries[step] ?? "");
    this.input.focus();
    this.load(cx);
    cx.notify();
  }

  move(by, cx) {
    const n = this.rows().length;
    if (!n) return;
    this.at = (this.at + by + n) % n;
    this.scroll.scroll_to_item(this.at);
    cx.notify();
  }

  cycle(what, by, cx) {
    if (this.busy) return;
    if (what === "type" && this.tab === "start") {
      this.type = (this.type + by + TYPES.length) % TYPES.length;
      localStorage.setItem("type", TYPES[this.type]);
      this.step = "first";
      this.queries = {};
      this.setQuery("");
    } else if (what === "machine") {
      const list = this.machineList();
      this.machine = list[(list.indexOf(this.machine) + by + list.length) % list.length];
      if (this.tab === "start") localStorage.setItem("machine", this.machine ?? "");
      if (this.step === "bookmark") this.step = "first";
      this.at = 0;
    } else if (what === "agent" && this.tab === "start") {
      this.agent = (this.agent + by + AGENTS.length) % AGENTS.length;
      localStorage.setItem("agent", AGENTS[this.agent]);
    } else return;
    this.error = "";
    this.load(cx);
    cx.notify();
  }

  switchTab(cx) {
    this.tab = this.tab === "start" ? "close" : "start";
    this.step = "first";
    this.marks.clear();
    this.error = "";
    this.setQuery("");
    this.input.focus();
    this.load(cx);
    cx.notify();
  }

  escape(cx) {
    if (this.busy) return;
    if (this.input.value()) this.setQuery("");
    else if (this.step === "linear") this.go("bookmark", cx);
    else if (this.step === "bookmark") this.go("first", cx);
    else return this.close();
    cx.notify();
  }

  tabKey(cx) {
    const row = this.rows()[this.at];
    if (!row) return;
    if (this.tab === "close" || this.step === "linear") {
      if (this.marks.has(row.key)) this.marks.delete(row.key);
      else this.marks.add(row.key);
      this.move(1, cx);
    } else if (!row.create) {
      this.setQuery(row.label);
      cx.notify();
    }
  }

  enter(cx) {
    if (this.busy) return;
    const rows = this.rows();
    const row = rows[this.at];
    if (this.tab === "close") return this.remove(rows, row, cx);
    if (this.step === "linear") return this.start(cx, rows);
    if (!row) return;
    const type = TYPES[this.type];
    if (type === "Workspace" && this.step === "first") {
      this.repo = row.item.repo;
      this.go("bookmark", cx);
      // Show what's here now, then again after origin is fetched.
      const on = this.machine;
      const repo = this.repo;
      cx.spawn(async (cx) => {
        await helper(["fetch", repo], on, 15_000).catch(() => null);
        if (this.repo === repo) this.load(cx, true);
      });
      return;
    }
    if (type === "Workspace") {
      this.bookmark = row.create ?? row.key;
      return this.offerLinear(cx);
    }
    this.target = row.create ?? row.key;
    this.start(cx, []);
  }

  // Linear issues for a new workspace, when the `linear` CLI has any.
  offerLinear(cx) {
    this.busy = true;
    cx.notify();
    cx.spawn(async (cx) => {
      if (this.linear === undefined)
        this.linear = await helper(["linear"], null, 25_000).catch(() => []);
      this.busy = false;
      if (this.linear.length) this.go("linear", cx);
      else this.start(cx, []);
      cx.notify();
    });
  }

  start(cx, linearRows) {
    const type = TYPES[this.type];
    const args =
      type === "Workspace"
        ? ["start", "workspace", this.repo, this.bookmark]
        : ["start", type.toLowerCase(), this.target];
    args.push("--agent", AGENTS[this.agent], "--focus");
    if (this.machine) args.push("--on", this.machine);
    for (const r of linearRows.filter((r) => this.marks.has(r.key)))
      args.push(r.item.kind === "project" ? "--linear-project" : "--linear-issue", r.item.id);
    this.busy = true;
    this.error = "";
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        await helper(args, null, 150_000);
        this.close();
      } catch (error) {
        this.error = String(error.message ?? error);
      }
      this.busy = false;
      cx.notify();
    });
  }

  remove(rows, row, cx) {
    const targets = this.marks.size ? rows.filter((r) => this.marks.has(r.key)) : row ? [row] : [];
    // Wait for the jj workspaces: closing must know which folder to clean up.
    if (!targets.length || this.data() === undefined) return;
    const on = this.machine;
    this.busy = true;
    this.error = "";
    cx.notify();
    cx.spawn(async (cx) => {
      const failed = [];
      for (const t of targets) {
        for (const s of t.ws ? this.spacesAt(t.ws.path) : [t.space])
          run("space.close", { id: s.id, confirmed: true });
        if (!t.ws) continue;
        try {
          const r = await helper(["remove", t.ws.path], on, 120_000);
          notify({
            title: `Removed ${t.label}`,
            body: r.kept
              ? `Its changes stay in jj as ${r.kept}.`
              : "The bookmark and its commits stay.",
            level: "success",
          });
        } catch (error) {
          failed.push(`${t.label}: ${error.message ?? error}`);
        }
      }
      this.busy = false;
      if (!failed.length) return this.close();
      this.error = failed.join("\n");
      this.marks.clear();
      this.load(cx, true);
      cx.notify();
    });
  }

  // The confirm's row: the current space, first in closeRows().
  confirmRow() {
    const row = this.closeRows()[0];
    return row?.space?.id === this.currentSpace()?.id ? row : null;
  }

  key(e, cx) {
    const m = e.modifiers;
    const plain = !m.control && !m.alt && !m.platform;
    // Ctrl alone: ctrl+shift is Herdr's (ctrl+shift+t is New tab).
    const ctrl = m.control && !m.alt && !m.platform && !m.shift;
    const k = e.key;
    if (this.confirm) {
      if (k === "escape") this.close();
      else if (k === "enter" && plain) this.remove(this.rows(), this.confirmRow(), cx);
      else return;
      return cx.stop_propagation();
    }
    if (k === "escape") this.escape(cx);
    else if (k === "enter" && plain) this.enter(cx);
    else if (k === "tab" && plain && !m.shift) this.tabKey(cx);
    else if (k === "down" || (ctrl && (k === "j" || k === "n"))) this.move(1, cx);
    else if (k === "up" || (ctrl && (k === "k" || k === "p"))) this.move(-1, cx);
    // Two tabs, so both keys toggle: either one always gets you back.
    else if (ctrl && (k === "h" || k === "l")) this.switchTab(cx);
    else if (ctrl && k === "t") this.cycle("type", 1, cx);
    else if (ctrl && k === "m") this.cycle("machine", 1, cx);
    else if (ctrl && k === "g") this.cycle("agent", 1, cx);
    else return;
    cx.stop_propagation();
  }

  // --- Drawing ---
  // Follows the shipped picker (`mods/picker`): a top popup, a 15px title with
  // an Esc badge, a search field, 32px rows, and dim secondary text. Theme colors only.

  render() {
    const t = theme();
    if (this.confirm) return this.confirmView(t);
    const start = this.tab === "start";
    return v_flex()
      .id("space")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .size_full()
      .min_h(0)
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .text_color(t.foreground)
      .child(this.title(t))
      .child(this.search(t))
      .child(this.options(t))
      .when(Boolean(this.error), (el) => el.child(this.errorLine(t, this.error)))
      .child(this.list(t))
      .when(!start, (el) => el.child(this.detail(t, this.rows()[this.at])))
      .child(this.hints(t));
  }

  confirmView(t) {
    const row = this.confirmRow();
    const ready = this.data() !== undefined;
    return v_flex()
      .id("space")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .size_full()
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .text_color(t.foreground)
      .child(
        h_flex()
          .items_center()
          .child(
            div()
              .flex_1()
              .text_size(15)
              .font_semibold()
              .child(row ? `Close ${row.label}?` : "No space is open."),
          )
          .child(this.escBadge(t)),
      )
      .child(this.detail(t, row))
      .when(Boolean(this.error), (el) => el.child(this.errorLine(t, this.error)))
      .child(div().flex_1())
      .child(
        this.hintLine(
          t,
          !ready
            ? "checking…"
            : row?.ws
              ? "↵ close and remove · esc cancel"
              : "↵ close · esc cancel",
          !ready,
        ),
      );
  }

  escBadge(t) {
    return div()
      .id("space-esc")
      .px(6)
      .py(2)
      .rounded(5)
      .text_size(11)
      .text_color(t.dim)
      .cursor_pointer()
      .hover((s) => s.bg(t.hover).text_color(t.foreground))
      .on_click(() => this.close())
      .child("Esc");
  }

  errorLine(t, text) {
    return div().px(10).text_size(12).text_color(t.blocked).child(text);
  }

  title(t) {
    const tab = (id, label) =>
      div()
        .id(`tab-${id}`)
        .text_size(15)
        .cursor_pointer()
        .when(this.tab === id, (el) => el.font_semibold().text_color(t.foreground))
        .when(this.tab !== id, (el) => el.text_color(t.dim).hover((s) => s.text_color(t.muted)))
        .on_click((_e, cx) => this.tab !== id && this.switchTab(cx))
        .child(label);
    return h_flex()
      .items_center()
      .gap(14)
      .child(tab("start", "Start"))
      .child(tab("close", "Close"))
      .child(div().flex_1())
      .child(this.escBadge(t));
  }

  search(t) {
    const crumb =
      this.tab === "start" && this.step === "bookmark"
        ? `${this.repo.split("/").pop()} ›`
        : this.tab === "start" && this.step === "linear"
          ? "Linear ›"
          : null;
    return h_flex()
      .h(36)
      .flex_none()
      .px(10)
      .gap(8)
      .items_center()
      .rounded(9)
      .border_1()
      .border_color(t.accent)
      .bg(t.background)
      .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
      .when(Boolean(crumb), (el) =>
        el.child(div().flex_none().text_size(12.8).text_color(t.muted).child(crumb)),
      )
      .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground));
  }

  // The chips as one quiet sentence: "Workspace · on <machine> · with claude".
  // A click on a value cycles it, as ctrl+t / ctrl+m / ctrl+g do.
  options(t) {
    const value = (what, text) =>
      div()
        .id(`opt-${what}`)
        .px(4)
        .rounded(4)
        .text_color(t.foreground)
        .cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => this.cycle(what, 1, cx))
        .child(text);
    const word = (text) => div().text_color(t.dim).child(text);
    const line = h_flex().px(6).gap(4).items_center().text_size(12);
    if (this.tab === "close")
      return line.child(word("on")).child(value("machine", this.machineLabel(this.machine)));
    return line
      .child(value("type", TYPES[this.type]))
      .child(word("·  on"))
      .child(value("machine", this.machineLabel(this.machine)))
      .child(word("·  with"))
      .child(value("agent", AGENTS[this.agent]));
  }

  list(t) {
    const data = this.data();
    const rows = this.rows();
    if (this.at >= rows.length) this.at = Math.max(0, rows.length - 1);
    const loading = data === undefined && (this.tab === "start" || !rows.length);
    const empty = !loading && !(data instanceof Error) && !rows.length;
    return v_flex()
      .id("rows")
      .flex_1()
      .min_h(0)
      .overflow_y_scroll()
      .track_scroll(this.scroll)
      .when(data instanceof Error, (el) =>
        el.child(this.errorLine(t, String(data?.message ?? data))),
      )
      .when(loading, (el) =>
        el.child(h_flex().px(14).h(32).items_center().text_color(t.dim).child("loading…")),
      )
      .when(empty, (el) =>
        el.child(h_flex().px(14).h(32).items_center().text_color(t.dim).child("Nothing matches.")),
      )
      .children(rows.map((r, i) => this.row(t, r, i)));
  }

  row(t, r, i) {
    const on = i === this.at;
    const marking = this.tab === "close" || this.step === "linear";
    const cut = r.split ? r.label.lastIndexOf("/") + 1 : 0;
    const label = h_flex()
      .flex_1()
      .min_w(0)
      .truncate()
      .text_color(r.tone ? t[r.tone] : t.foreground)
      .when(Boolean(r.current), (el) => el.font_semibold())
      .when(cut > 0, (el) => el.child(div().text_color(t.dim).child(r.label.slice(0, cut))))
      .child(r.label.slice(cut));
    const side = [r.state, r.right].filter(Boolean).join("  ");
    return (
      h_flex()
        .id(`row-${i}`)
        .flex_none()
        .mx(4)
        .px(10)
        .h(32)
        .gap(10)
        .items_center()
        .rounded(7)
        .cursor_pointer()
        // selected, not hover: in the Nord theme hover is the popover color.
        .when(on, (el) => el.bg(t.selected))
        .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
        .on_click((_e, cx) => {
          this.at = i;
          cx.notify();
        })
        .when(marking, (el) =>
          el.child(
            div()
              .w(12)
              .flex_none()
              .text_color(t.accent)
              .child(this.marks.has(r.key) ? "●" : ""),
          ),
        )
        .when(Boolean(r.create), (el) =>
          el.child(div().w(12).flex_none().text_color(t.muted).child("+")),
        )
        .child(label)
        .when(Boolean(side), (el) =>
          el.child(div().flex_none().text_size(11).text_color(t.dim).child(side)),
        )
    );
  }

  // What Enter does to the selected space, in a short block under the list.
  detail(t, row) {
    const block = v_flex().flex_none().px(14).gap(4).text_size(12).text_color(t.muted);
    if (!row) return block;
    const w = row.ws;
    const open = w ? this.spacesAt(w.path) : [row.space];
    const active = open.some((s) => s.status === "working" || s.status === "blocked");
    const facts = [];
    if (open.length)
      facts.push(
        open.map((s) => `${s.tabs.length} tabs${s.status ? ` · ${s.status}` : ""}`).join(", "),
      );
    if (w?.bookmarks.length)
      facts.push(w.bookmarks.map((b) => `${b.name}${b.synced ? "" : " (not pushed)"}`).join(", "));
    if (w?.changes.length)
      facts.push(`${w.changes.length} changed file${w.changes.length === 1 ? "" : "s"}`);
    const outcome = w
      ? "Closes the space, forgets the jj workspace and trashes its folder. Commits and changes stay in jj."
      : this.data() === undefined
        ? "Checking for a jj workspace…"
        : "Closes the space and ends its terminals. The folder stays.";
    return block
      .child(
        div()
          .truncate()
          .text_color(t.dim)
          .child(w?.path ?? row.space?.folder ?? "~"),
      )
      .when(facts.length > 0, (el) => el.child(div().truncate().child(facts.join("  ·  "))))
      .when(Boolean(w?.changes.length), (el) =>
        el.child(div().truncate().text_color(t.working).child(w.changes.slice(0, 3).join("   "))),
      )
      .when(active, (el) =>
        el.child(
          div().text_color(t.working).child("An agent is still active here. Its terminals end."),
        ),
      )
      .child(div().text_color(t.dim).child(outcome));
  }

  hintLine(t, text, spin = false) {
    return h_flex()
      .flex_none()
      .px(6)
      .gap(6)
      .text_size(11)
      .text_color(t.dim)
      .when(spin, (el) => el.child(div().frames(SPINNER, 90)))
      .child(text);
  }

  hints(t) {
    if (this.busy) return this.hintLine(t, "working…", true);
    const chips = "^T type · ^M machine · ^G agent";
    let text;
    if (this.tab === "close") {
      text = `${this.rows()[this.at]?.ws ? "↵ close and remove" : "↵ close"} · tab mark · ^M machine · ^L start`;
    } else if (this.step === "linear") {
      text = "tab mark · ↵ start (nothing marked: skip) · esc back";
    } else if (this.step === "bookmark") {
      text = `↵ start · tab fill · esc back · ${chips}`;
    } else if (TYPES[this.type] === "Workspace") {
      text = `↵ bookmarks · ${chips} · ^L close`;
    } else {
      text = `↵ start · tab fill · ${chips} · ^L close`;
    }
    return this.hintLine(t, text);
  }
}
