// Toggle to the machine and back: show the machine agent of the focused
// space's machine, the terminal named `machine` in space `machine` (see
// "Machine Agent" in the repo's AGENTS.md), or, from that space, the space
// you came from. `herdr-machine-agent` starts or repairs the agent there.
import { View, div } from "gpui-kit";
import {
  checking,
  closeOverlay,
  exec,
  focused,
  home,
  notify,
  props,
  run,
  setShared,
  shared,
  spaces,
  terminals,
} from "herdr";

const ENSURE = `${home()}/.local/bin/herdr-machine-agent`; // homes match across machines

const machineOf = (address) => (address.includes("/") ? address.split("/")[0] : null);
const qualify = (machine, id) => (machine ? `${machine}/${id}` : id);

// The focused space's machine (null: this computer) and its `machine` terminal.
const target = () => {
  // focused() can be null while this popup holds focus: then the shown space.
  const here = spaces().find((s) => s.id === focused()?.space) ?? spaces().find((s) => s.active);
  const machine = here?.machine ?? null;
  const term = terminals().find(
    (t) => t.name === "machine" && t.state === "live" && machineOf(t.address) === machine,
  );
  return { here, machine, term, space: qualify(machine, "machine") };
};

// Start or repair it there.
const ensure = (t) =>
  exec(ENSURE, [], { on: t.machine, timeout: 90000 }).then((r) => {
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
    this.handle = cx.focus_handle();
    if (checking()) return;
    // Act once the (invisible) popup is up, then close it.
    cx.timer.after(0, () => this.act());
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  act() {
    const t = target();
    if (t.here && t.here.id === t.space) {
      // shared, not localStorage: each popup the prefix opens gets its own store.
      const back = shared("machine.back");
      if (back && spaces().some((s) => s.id === back)) run("space.select", { id: back });
      return this.dismiss();
    }
    if (t.here) setShared("machine.back", t.here.id);
    const show = () => run("space.select", { id: t.space });
    // No terminal: this popup stays until there is one.
    if (!t.term) return ensure(t).then((ok) => (ok && show(), this.dismiss()));
    // A terminal can be a shell with no Claude (after a reboot, or Claude
    // exited): repair it in the background. exec starts at the call, before
    // closing cancels this view's tasks.
    show();
    ensure(t);
    this.dismiss();
  }

  render() {
    return div().id("machine").track_focus(this.handle);
  }
}
