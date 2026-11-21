---
name: herdr
description: "Control Herdr: the Herdr app and herdr-core (`hc`), which run coding agents and programs in terminals that stay alive. Use only when the user explicitly mentions Herdr or asks to use Herdr to inspect or control terminals, tabs, spaces, commands, or another agent. Do not use merely because a task could benefit from a background terminal, delegation, or parallel work. Requires HC_TERMINAL_ID."
---

# Herdr

Check that this agent runs in a herdr-core terminal:

```bash
test -n "${HC_TERMINAL_ID:-}" || echo "not in Herdr"
```

Not in Herdr: say so and stop.

## Read the manuals first

The installed binaries print their own current manuals. Read both before the
first command, and follow them:

```bash
hc --skill          # terminals, agents, waiting, reading, machines
herdr-app --skill   # the window: spaces, tabs, panes, `herdr-app do`
```

`herdr` is the old TUI. It is removed. Ignore its commands and `HERDR_*` variables.

## Rules on this machine

- Never stop or restart a core (`hc server stop|restart`) unless the user asks.
  The user's agents run in it.
- Never start a core from an agent shell. It keeps this shell's environment,
  and every terminal it starts inherits it (Claude then stops saving transcripts).
- Put options before the program: `hc run --bg --json --name x pi "task"`.
  Anything after the program name goes to the program.
- agy takes its first task with `-i`: `hc run --bg --name x agy --model <m> -i "task"`.
- Run `trust-workspace "$PWD"` before you start an agent in a new folder, or it
  stops on a trust dialog.
- Spaces for repos and jj workspaces: the `herdr-space` helper
  (`herdr-space --help`). The app's space popup (`ctrl+u t`, `ctrl+u e`) uses it.
