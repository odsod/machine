// Talk to the machine: the machine agent of the focused space's machine, the
// terminal named `machine` in space `machine` (see "Machine Agent" in the
// repo's AGENTS.md). `herdr-machine-agent` starts or repairs it there.
//
// props().action:
// - "ask" (default): a text box. Enter sends the text, with where you are.
// - "peek": peek at its terminal over the current tab.
// - "go": show its space.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import {
  closeOverlay,
  exec,
  focused,
  home,
  notify,
  props,
  run,
  spaces,
  terminals,
  theme,
} from "herdr";

const ENSURE = `${home()}/.local/bin/herdr-machine-agent`; // homes match across machines
// This computer's name, as odsod-spaces shows it.
let hostname = null;

const machineOf = (address) => (address.includes("/") ? address.split("/")[0] : null);
const qualify = (machine, id) => (machine ? `${machine}/${id}` : id);

// The focused space's machine (null: this computer) and its `machine` terminal.
const target = () => {
  const here = spaces().find((s) => s.id === focused()?.space);
  const machine = here?.machine ?? null;
  const term = terminals().find(
    (t) => t.name === "machine" && t.state === "live" && machineOf(t.address) === machine,
  );
  return { here, machine, term, space: qualify(machine, "machine") };
};

// Where the person is, so "this space" means something to the agent.
const context = ({ here }) =>
  here
    ? `\n\n[sent from space "${here.name}", folder ${focused()?.cwd ?? here.folder}, on ${here.machine ?? hostname}]`
    : "";

// Start or repair it there, then send the message (if any) once it is up.
const ensure = (t, message) =>
  exec(ENSURE, message ? [message] : [], { on: t.machine, timeout: 90000 }).then((r) => {
    if (r.code !== 0)
      notify({
        title: "machine",
        body: r.stderr.trim() || "herdr-machine-agent failed",
        level: "error",
      });
    return r.code === 0;
  });

export default class Machine extends View {
  init(_props, cx) {
    this.action = props()?.action ?? "ask";
    this.text = "";
    this.handle = cx.focus_handle();
    if (this.action === "ask") {
      this.input = InputState.new({ value: "" });
      this.input.on("change", (_e, cx) => {
        this.text = this.input.value();
        cx.notify();
      });
      this.input.on("submit", () => this.send());
      this.input.focus();
      cx.timer.after(600, () => this.input.focus());
    }
    if (!hostname)
      cx.spawn(async (cx) => {
        try {
          hostname = (await exec("uname", ["-n"])).stdout.trim() || null;
        } catch {}
        cx.notify();
      });
    // Peek and go act once the popup is up, then close it.
    if (this.action !== "ask") cx.timer.after(0, () => this.act());
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  act() {
    const t = target();
    const show = () => run("space.select", { id: t.space });
    // Go to one that isn't running: this (invisible) popup stays until it is.
    if (this.action === "go" && !t.term)
      return ensure(t).then((ok) => (ok && show(), this.dismiss()));
    this.dismiss();
    if (this.action === "peek") {
      if (t.term) run("terminal.peek", { terminal: t.term.address });
      else
        notify({
          title: "machine",
          body: `Not running on ${t.machine ?? hostname}. Ctrl+U g starts it.`,
        });
    } else if (this.action === "go") {
      show();
    }
  }

  send() {
    const text = this.text.trim();
    if (!text) return this.dismiss();
    const t = target();
    this.dismiss();
    // exec starts its subprocess at the call, before closing cancels this view's tasks.
    ensure(t, text + context(t));
  }

  key(e, cx) {
    if (e.key === "escape") {
      this.dismiss();
      cx.stop_propagation();
    }
  }

  render() {
    const t = theme();
    if (this.action !== "ask") return div().id("machine").track_focus(this.handle);
    const x = target();
    const where = `${x.machine ?? hostname ?? "this computer"} · ${x.term ? (x.term.status ?? "running") : "not running: Enter starts it"}`;
    return v_flex()
      .id("machine")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .w_full()
      .p(14)
      .gap(10)
      .bg(t.popover)
      .text_color(t.foreground)
      .child(
        h_flex()
          .items_center()
          .gap(8)
          .child(div().text_size(13).font_semibold().child("machine"))
          .child(div().flex_1().text_size(11.5).text_color(t.dim).child(where))
          .child(div().text_size(11).text_color(t.dim).child("Enter send · Esc")),
      )
      .child(
        Input.new(this.input)
          .h(36)
          .px(10)
          .rounded(9)
          .border_1()
          .border_color(t.accent)
          .bg(t.background)
          .text_size(12.8)
          .text_color(t.foreground),
      );
  }
}
