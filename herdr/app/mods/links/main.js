// Pick a link printed in the focused terminal: Enter opens it, ctrl+y copies it.
// The community pickers for the Herdr TUI (herdr-urlview, herdr-url-picker) do
// the same with `herdr pane read`; here `hc read` gives the screen and history
// with soft-wrapped lines already joined.
//
// Open and copy run in the app, on the computer you sit at, also for a
// terminal on another machine.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, Input, InputState, ScrollHandle } from "gpui-base";
import { checking, closeOverlay, exec, focused, hc, notify, props, theme } from "herdr";

const HISTORY_LINES = "5000";
const URL = /https?:\/\/[^\s<>"'`\\]+/g;

// Drop trailing punctuation, and closing brackets with no opening partner.
const PAIRS = { ")": "(", "]": "[", "}": "{" };
const count = (text, c) => text.split(c).length - 1;
const trim = (url) => {
  for (;;) {
    const last = url.at(-1);
    if (".,;:!?*'".includes(last)) url = url.slice(0, -1);
    else if (PAIRS[last] && count(url, last) > count(url, PAIRS[last])) url = url.slice(0, -1);
    else return url;
  }
};

// Unique links, newest (lowest on the screen) first.
const links = (text) => {
  const seen = new Set();
  const found = [];
  for (const line of text.split("\n").reverse()) {
    for (const m of [...line.matchAll(URL)].reverse()) {
      const url = trim(m[0]);
      if (url.length > 8 && !seen.has(url)) {
        seen.add(url);
        found.push(url);
      }
    }
  }
  return found;
};

// Every word of the query appears in the link, in any order.
const matches = (query, text) => {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  const hay = text.toLowerCase();
  return words.every((w) => hay.includes(w));
};

export default class Links extends View {
  init(_props, cx) {
    this.terminal = focused()?.terminal ?? null;
    this.found = undefined; // undefined while reading, then a list or an Error
    this.at = 0;
    this.scroll = ScrollHandle.new();
    this.input = InputState.new({ value: "", placeholder: "Filter links" });
    this.input.on("change", (_e, cx) => {
      this.at = 0;
      cx.notify();
    });
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(100, () => this.input.focus());
    if (checking()) return;
    if (!this.terminal) {
      this.found = new Error("No terminal is focused.");
      return;
    }
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["read", this.terminal, "--lines", HISTORY_LINES]);
        if (r.code !== 0) throw new Error(r.stderr.trim() || "hc read failed");
        this.found = links(r.stdout);
      } catch (error) {
        this.found = error instanceof Error ? error : new Error(String(error));
      }
      cx.notify();
    });
  }

  rows() {
    if (!Array.isArray(this.found)) return [];
    const query = this.input.value();
    return this.found.filter((url) => matches(query, url));
  }

  close() {
    closeOverlay(props().overlay);
  }

  move(by, cx) {
    const n = this.rows().length;
    if (!n) return;
    this.at = (this.at + by + n) % n;
    this.scroll.scroll_to_item(this.at);
    cx.notify();
  }

  async use(how) {
    const url = this.rows()[this.at];
    if (!url) return;
    this.close();
    const [command, args, done] =
      how === "copy" ? ["wl-copy", ["--", url], "Copied link"] : ["xdg-open", [url], null];
    const r = await exec(command, args, { timeout: 10_000 }).catch((error) => ({
      code: -1,
      stderr: String(error),
    }));
    if (r.code !== 0) notify({ title: `${command} failed`, body: r.stderr.trim(), level: "error" });
    else if (done) notify({ title: done, body: url, level: "success" });
  }

  key(e, cx) {
    const m = e.modifiers;
    const plain = !m.control && !m.alt && !m.platform;
    const ctrl = m.control && !m.alt && !m.platform && !m.shift;
    const k = e.key;
    if (k === "escape") this.close();
    else if (k === "enter" && plain) this.use("open");
    else if (ctrl && k === "y") this.use("copy");
    else if (k === "down" || (ctrl && (k === "j" || k === "n"))) this.move(1, cx);
    else if (k === "up" || (ctrl && (k === "k" || k === "p"))) this.move(-1, cx);
    else return;
    cx.stop_propagation();
  }

  // --- Drawing ---
  // The same look as `mods/space`: a title with an Esc badge, a search field,
  // 32px rows, and a dim hint line. Theme colors only.

  render() {
    const t = theme();
    return v_flex()
      .id("links")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .size_full()
      .min_h(0)
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .text_color(t.foreground)
      .child(
        h_flex()
          .items_center()
          .child(div().flex_1().text_size(15).font_semibold().child("Links"))
          .child(this.escBadge(t)),
      )
      .child(this.search(t))
      .child(this.list(t))
      .child(
        h_flex()
          .flex_none()
          .px(6)
          .text_size(11)
          .text_color(t.dim)
          .child("↵ open · ^Y copy · ^J/^K move · esc close"),
      );
  }

  escBadge(t) {
    return div()
      .id("links-esc")
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

  search(t) {
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
      .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground));
  }

  list(t) {
    const rows = this.rows();
    if (this.at >= rows.length) this.at = Math.max(0, rows.length - 1);
    const message =
      this.found === undefined
        ? "reading…"
        : this.found instanceof Error
          ? this.found.message
          : !this.found.length
            ? "No links in this terminal."
            : !rows.length
              ? "Nothing matches."
              : null;
    return v_flex()
      .id("rows")
      .flex_1()
      .min_h(0)
      .overflow_y_scroll()
      .track_scroll(this.scroll)
      .when(Boolean(message), (el) =>
        el.child(
          h_flex()
            .px(14)
            .h(32)
            .items_center()
            .text_color(this.found instanceof Error ? t.blocked : t.dim)
            .child(message),
        ),
      )
      .children(rows.map((url, i) => this.row(t, url, i)));
  }

  row(t, url, i) {
    const cut = url.indexOf("/", url.indexOf("//") + 2);
    const host = cut < 0 ? url : url.slice(0, cut);
    const rest = cut < 0 ? "" : url.slice(cut);
    return h_flex()
      .id(`row-${i}`)
      .flex_none()
      .mx(4)
      .px(10)
      .h(32)
      .items_center()
      .rounded(7)
      .cursor_pointer()
      .when(i === this.at, (el) => el.bg(t.selected))
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => {
        this.at = i;
        cx.notify();
      })
      .child(
        h_flex()
          .flex_1()
          .min_w(0)
          .truncate()
          .child(div().text_color(t.foreground).child(host))
          .child(div().text_color(t.dim).child(rest)),
      );
  }
}
