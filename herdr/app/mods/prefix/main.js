// A tmux-style prefix key, adapted from the upstream example at
// herdr.dev/mods/herdrdev/tmux-prefix (herdrdev/herdr-layout-examples).
//
// Changes from that example:
// - The prefix is ctrl+u, to match herdr/config.toml [keys] for the Herdr TUI.
// - The second key works with or without ctrl: `prefix ctrl+h` and `prefix h`.
// - Every key closes the hint, as in the TUI: no repeat window.
// - The hint is a one-line bar; `?` shows the whole list.
//
// BINDINGS mirror the TUI [keys]. `herdr-app commands` lists what exists: copy
// mode has no app equivalent, and detach is `window.close`, since the core
// keeps the terminals running.
import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { closeOverlay, focused, hc, nextCommand, props, run, theme } from "herdr";

const PREFIX = "ctrl+u";
const BINDINGS = [
  ["ctrl+h", "Focus left", "pane.go", { direction: "left" }],
  ["ctrl+j", "Focus down", "pane.go", { direction: "down" }],
  ["ctrl+k", "Focus up", "pane.go", { direction: "up" }],
  ["ctrl+l", "Focus right", "pane.go", { direction: "right" }],
  ["left", "Focus left", "pane.go", { direction: "left" }],
  ["down", "Focus down", "pane.go", { direction: "down" }],
  ["up", "Focus up", "pane.go", { direction: "up" }],
  ["right", "Focus right", "pane.go", { direction: "right" }],
  ["ctrl+s", "Split down", "pane.split", { direction: "down" }],
  ["ctrl+v", "Split right", "pane.split", { direction: "right" }],
  ["ctrl+d", "Close pane", "pane.close"],
  ["ctrl+z", "Zoom pane", "pane.zoom"],
  ["ctrl+n", "Next tab", "tab.next"],
  ["ctrl+b", "Previous tab", "tab.prev"],
  ["ctrl+w", "New tab", "tab.new"],
  ["ctrl+m", "Rename tab", "tab.rename"],
  ["ctrl+f", "Goto picker", "mod.open", { name: "picker" }],
  ["ctrl+y", "Close space", "space.close"],
  ["ctrl+q", "Detach (close window)", "window.close"],
  ...Array.from({ length: 10 }, (_, i) => [
    String(i),
    `Tab ${i === 0 ? 10 : i}`,
    "tab.select",
    { index: i === 0 ? 10 : i },
  ]),
];
// The one-line hint. Keep it in step with BINDINGS.
const HINT =
  "h j k l focus · s v split · d close · z zoom · n b tab · w new · m rename · f goto · q detach";

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.all = false;
    // keys.json binds the prefix to `prefix.send-prefix` while this mod has
    // focus, so it beats the global binding that opens the mod.
    cx.spawn(async (cx) => {
      for (;;) {
        await nextCommand();
        this.sendPrefix(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  sendPrefix(cx) {
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    // hc starts its subprocess at the call, before closing cancels this view's tasks.
    const pending = hc(["keys", terminal, PREFIX]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  key(e, cx) {
    cx.stop_propagation();
    const m = e.modifiers;
    if (e.key === "escape") return this.dismiss();
    // Second keys may carry ctrl (as in the TUI) or not (as in tmux).
    const ctrl = m.control && !m.alt && !m.platform;
    const plain = !m.control && !m.alt && !m.platform;
    const key = m.shift && e.key.length === 1 ? e.key.toUpperCase() : (e.key_char ?? e.key);
    if (ctrl && `ctrl+${e.key}` === PREFIX) return this.sendPrefix(cx);
    if (plain && key === "?") {
      this.all = !this.all;
      cx.notify();
      return;
    }
    const lookup = ctrl ? [`ctrl+${e.key}`] : plain ? [`ctrl+${e.key}`, key] : [];
    const binding = lookup.map((name) => BINDINGS.find((b) => b[0] === name)).find(Boolean);
    if (!binding) return this.dismiss();
    const [, , command, args = {}] = binding;
    this.dismiss();
    run(command, args);
  }

  render() {
    const t = theme();
    const shell = (...children) =>
      v_flex()
        .id("prefix")
        .track_focus(this.handle)
        .on_key_down((e, cx) => this.key(e, cx))
        .bg(t.chrome)
        .border_t(1)
        .border_color(t.border)
        .text_color(t.foreground)
        .text_size(12)
        .children(children);
    const line = (...children) => h_flex().px(12).p(8).gap(10).items_center().children(children);
    // The hint is a status line, not a menu: one line while it waits, and the
    // whole binding list only when `?` asks for it.
    if (!this.all) {
      return shell(
        line(
          div().font_semibold().child("Ctrl+U"),
          div().text_color(t.muted).child(HINT),
          div().text_color(t.dim).child("? all"),
        ),
      );
    }
    return shell(
      v_flex()
        .p(14)
        .gap(8)
        .child(
          h_flex()
            .justify_between()
            .child(div().font_semibold().child("Ctrl+U · waiting for a key"))
            .child(div().text_color(t.muted).child("Esc cancel · ^U send prefix")),
        )
        .child(
          v_flex()
            .h(280)
            .min_h(0)
            .overflow_y_scrollbar()
            .children(
              BINDINGS.map(([key, label]) =>
                h_flex()
                  .h(20)
                  .flex_none()
                  .items_center()
                  .gap(12)
                  .child(div().w(52).text_color(t.accent).child(key))
                  .child(div().flex_1().child(label)),
              ),
            ),
        )
        .child(div().text_color(t.muted).child("0–9 tabs (0 = 10) · arrows focus · ? hide list")),
    );
  }
}
