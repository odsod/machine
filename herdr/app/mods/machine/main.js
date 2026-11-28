// Toggle to an agent and back: show the agent named `props().agent`
// (`machine`, the default, or a vault: `brain`, `house`, `company`) of the
// focused space's machine, the terminal of that name in the space of that name
// (see "Machine Agent" in the repo's AGENTS.md), or, from that space, the
// space you came from. Only with no live terminal there does
// `herdr-machine-agent --agent <name>` set the agent up from scratch.
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
const AGENTS = ["machine", "brain", "house", "company"];
// Agents being started, by space id: {id: ms}. The sidebar (odsod-spaces)
// spins the agent's row while its id is here.
const STARTING = "agents.starting";
const setStarting = (id, on) => {
  const s = { ...(shared(STARTING) ?? {}) };
  if (on) s[id] = Date.now();
  else delete s[id];
  setShared(STARTING, s);
};

// The focused space's machine (null: this computer) and its agent's terminal.
const target = (name) => {
  // focused() can be null while this popup holds focus: then the shown space.
  const here = spaces().find((s) => s.id === focused()?.space) ?? spaces().find((s) => s.active);
  const machine = here?.machine ?? null;
  const term = terminals().find(
    (t) => t.name === name && t.state === "live" && machineOf(t.address) === machine,
  );
  const agentHere = AGENTS.some((a) => here?.id === qualify(machine, a));
  return { name, here, agentHere, machine, term, space: qualify(machine, name) };
};

// Start or repair it there.
const ensure = (t) =>
  exec(ENSURE, ["--agent", t.name], { on: t.machine, timeout: 90000 }).then((r) => {
    if (r.code !== 0)
      notify({
        title: t.name,
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
    const t = target(props().agent ?? "machine");
    if (t.here && t.here.id === t.space) {
      // shared, not localStorage: each popup the prefix opens gets its own store.
      const back = shared("machine.back");
      if (back && spaces().some((s) => s.id === back)) run("space.select", { id: back });
      return this.dismiss();
    }
    // Back goes to the last space that isn't an agent's, so hopping between
    // agents still returns there.
    if (t.here && !t.agentHere) setShared("machine.back", t.here.id);
    const show = () => run("space.select", { id: t.space });
    // No terminal: this popup stays until there is one.
    if (!t.term) {
      setStarting(t.space, true);
      return ensure(t).then((ok) => {
        setStarting(t.space, false);
        if (ok) show();
        this.dismiss();
      });
    }
    // A terminal is left as it is: a shell with no Claude stays a shell.
    show();
    this.dismiss();
  }

  render() {
    return div().id("machine").track_focus(this.handle);
  }
}
