---
name: agent-team
description: "Compose the agent team of this Herdr space that works until an outcome is realized, or decide this terminal can realize it alone. Use when the user invokes /agent-team, asks to set up an agent team, orchestrate another agent terminal, assign work across claude, codex, agy, or pi, or when a smart agent on a long plan should offload mechanical work to preserve its own context. Do not use for a trivial one-file edit, and do not use merely to inspect terminals. Requires HC_TERMINAL_ID."
---

# Agent Team

An agent team is live agents in herdr-core terminals plus a brief, working until an outcome is realized. The outcome is an end state, not a work list. Stop when the done-when check passes. Pick harnesses and responsibilities for this outcome, agree them, then run. Do not freeze standing assignments.

The invoking agent is the **orchestrator** unless the user names someone else. It stays in this terminal. A team is optional: work alone, and delegate only a unit that is worth it. Read `hc --skill` for CLI details.

**One team per space.** Each Herdr space has a name and holds at most one agent team. The team has the same name as the space. Never give the team a name of its own, and never start a second team in a space. Team agents stay in its space.

**Addresses, names, and roles.** Each member has three handles:

| Handle  | Example              | Use it for                                     |
| ------- | -------------------- | ---------------------------------------------- |
| Address | `t7`                 | Every `hc` command                             |
| Name    | `auth-refactor-impl` | `hc run --name`: `<team>-<role>`, display only |
| Role    | `impl`               | Findings file name, brief, Handoff lines       |

- Target agents by address only. Addresses are stable while the terminal lives.
- Names are unique among all live terminals, so a bare `impl` collides with other teams. Use `<team>-<role>`, at most 32 characters of `[a-z0-9_-]`.
- Write each member's address into the brief right after you start it.
- Roles match `[a-z][a-z0-9_-]{0,31}` and are unique in the team.

**Primed vs vacuum.** Prime agents that judge or coordinate (orchestrate, design, review, write, council): their first prompt is load `/agent-team`, their role, and the brief path. Everything else works in a vacuum: one unit, an output path, a stop. Never show a vacuum agent this skill, the brief, or Handoff tokens. The orchestrator holds the protocol for it.

## When to add an agent

Add an agent only when this pane fails one of two tests:

- **Capability.** The unit needs something this pane lacks: grind (implement, refactor, run tests), multimodal or parallel work, web research, or a different frame.
- **Context.** Doing the unit here would fill this window with diffs, style corpora, dumps, or bulk files, and leave it unable to hold the plan.

Close a worker as soon as its last unit is accepted.

## Roster

| Kind     | Default model              | Give it                                                                | Do not give it alone                    | Context reset             |
| -------- | -------------------------- | ---------------------------------------------------------------------- | --------------------------------------- | ------------------------- |
| `claude` | Opus 5.5                   | orchestrate, design, architecture                                      | bulk or multimodal grind                | `/compact`, then `/clear` |
| `codex`  | Sol 6.1                    | fallback for Opus 5.5 (unavailable, rate-limited, or stuck)            | bulk or multimodal grind                | `/compact`, then `/new`   |
| `agy`    | Gemini 4 Neon (Medium)     | write, adversarial review, multimodal or large corpus (fans subagents) | long-horizon orchestrate or merge       | `/compact`, then `/clear` |
| `agy`    | Gemini 4 Hydrogen (Medium) | web research                                                           | design, review, or write                | `/compact`, then `/clear` |
| `pi`     | DeepSeek V4.1 Flash        | grind: implement, refactor, run tests and smoke tests                  | design or review without a second agent | `/new`                    |

Default team: Opus 5.5 orchestrates and designs, `pi` does the grind (implement, refactor, tests), Gemini 4 Neon reviews and writes, Gemini 4 Hydrogen does web research.

The program is the Kind column, with its first task as the last argument. This machine pins claude, codex, and pi to the model above.

| Kind     | Command                                                                        |
| -------- | ------------------------------------------------------------------------------ |
| `claude` | `claude "<task>"`                                                              |
| `codex`  | `codex --dangerously-bypass-hook-trust --no-daemon "<task>"`                   |
| `agy`    | `agy --model gemini-4-neon-medium -i "<task>"` (or `gemini-4-hydrogen-medium`) |
| `pi`     | `pi "<task>"`                                                                  |

Codex without `--dangerously-bypass-hook-trust` can stop on a hook review screen. agy reads its first task only from `-i`.

Workers never need approval: claude settings use `bypassPermissions`, agy settings use `always-proceed`, codex config sets `approval_policy = "never"`, and pi has no approvals. A trust or approval dialog on a worker is a config bug: answer it once, then tell the user.

For bulk and web research, agy writes `report.md` and the orchestrator reads only that file.

Web research is vacuum work, so put these rules in its unit prompt:

- Give the URL of each key reference next to the claim it supports.
- Fetch every cited URL in this session (`defuddle parse <url> --md`). Never cite a URL from memory.
- Drop or replace a URL that fails, redirects to an unrelated page, or does not support the claim.
- Record the publish date, update date, or version of each source. Flag a source that a newer release or doc replaces.
- End `report.md` with a References list: URL, date or version, and one line on what it supports.

Responsibilities do not cross unless assigned: design does not ship code, implement does not redefine the outcome, write does not touch implementation or architecture, verify does not expand scope, bulk does not touch architecture. Write output is short sentences in the repo `AGENTS.md` style.

## Flow

### 1. Set up

```bash
test -n "${HC_TERMINAL_ID:-}" || echo "not in Herdr"
space="$(hc get "$HC_TERMINAL_ID" --json | jq -r '.labels["herdr.space"]')"
team="$(herdr-app ls | jq -r --arg s "$space" '.spaces[] | select(.id == $s) | .name' | tr 'A-Z/ ' 'a-z--')"
test -f "/tmp/agent-team/$team/brief.md" && echo "team exists"
```

- Not in Herdr: say so and stop.
- No space (a terminal started outside the app): name the team for the outcome (short, lowercase, like `auth-refactor`). In the app, rename the space to match with `herdr-app do space.rename --id "$space" --name <name>`.
- Brief exists and Handoff does not end with `orchestrator: team closed`: a live team exists. Continue it from Handoff. A closed team's brief: write a new one over it.

### 2. Propose, then agree

Propose, then wait for the user. Members may be this terminal only.

- Outcome in one paragraph (what will be true)
- Units, with keep or delegate, and the capability or context reason
- Workers for delegated units only, each with a role and a kind
- Done when: an exact command or proof that this pane can run without the worker

If the outcome is still a question, ask. Do not staff a team to invent it.

### 3. Write the brief

Write `/tmp/agent-team/<team>/brief.md`, never in the repo. Findings go to `<role>.md` in the same dir.

```markdown
# Team: <team>

Space: <space-id>

Outcome: …
Done when: <command or proof that it holds>

## Members

<!-- role | address | harness/model | responsibilities -->

- orchestrator | t2 | claude/opus-5.5 | orchestrate, design
- impl | <address> | pi/deepseek-v4.1-flash | implement # add when you delegate

## Units

- design: keep
- implement: delegate

## Handoff

- worker tokens: PHASE_COMPLETE | BLOCKED
- (append-only; orchestrator decisions in prose)
```

### 4. Spawn when you delegate

Spawn a worker only when its unit is next. Reuse an idle member of the right kind. Do not create a space or worktree unless the user asks.

Put the first task in `hc run`: a send to a booting agent can be dropped. Options go before the program.

Start each worker in a tab of this space, one tab per topic: workers on the same topic (a council, two researchers) share a tab. The label sets the tab's id, which is global across spaces: prefix it with the space. Rename the tab once so the user sees the topic.

```bash
trust-workspace "$PWD"   # trust this dir in every harness (idempotent)
t="$(hc run --bg --json --name "$team-impl" --cwd "$PWD" \
  --label herdr.space="$space" --label herdr.tab="$space-impl" \
  pi "Implement <unit>. Write /tmp/agent-team/<team>/impl.md. Stop when done." | jq -r .address)"
herdr-app do tab.rename --id "$space-impl" --name impl
hc wait "$t" --timeout <seconds that fit the unit>
```

Workers end when this terminal ends, and a tab closes when its last worker ends. Run builds, tests and watchers hidden (no labels).

`hc wait` waits until the agent stops working. An agent that reports no status (`hc get "$t"` shows `status: null`, as codex can) makes `hc wait` wait for exit: read its screen with `hc read "$t"` instead. Before you act on a stuck worker, read the screen:

- Input box empty and status `idle`: send the task once with `hc send "$t" "<task>"`.
- Task text still in the input box: `hc keys "$t" enter`.
- `working`: wait again.
- `blocked`: read the dialog and ask the user.

Still stuck after one resend: tell the user.

### 5. Run

A unit is finished when its findings file exists, the agreed check passes, or a primed worker writes a token to Handoff. `hc wait` returning is not enough: it tracks status, not a turn, and an `idle` agy can still have subagents running.

- Review the diff and the check, not the worker's claims.
- Append a prose Handoff line for each decision (`orchestrator → impl: fix cycle 1, see impl.md`). A restart uses these to tell reviewed from unreviewed work.
- A delegated unit gets at most two fix cycles. Then ask the user.
- Unclear: write an open question in the brief. Do not invent.
- Workers may make local `jj` commits. Nobody pushes unless asked.
- Only the orchestrator declares the outcome realized.
- After a restart: read the brief, check its addresses with `hc ls`, continue from Handoff. Workers end with their orchestrator, so a restart usually means you start them again.

### 6. Clean up

The outcome is not realized while the team still runs. Clean up yourself before the final report:

- End every worker (`hc kill <t>`, then `hc rm <t>`), and close any pane or tab the team opened. Then check that `hc ls` shows no `<team>-` terminals.
- Worker jj workspaces: check that each worker's commits are in the stack (`jj log -r '<ws>@- & ~::<tip>'` is empty), then `jj workspace forget <ws>` and remove the directory.
- Stop dev servers and other long processes the team started, unless the user needs them next. Say which ones you left running, and why.
- Append `orchestrator: team closed` to Handoff.

Something you cannot close safely (unique work, a process the user owns): name it in the final report, with the command to close it.

## Shapes

**Council.** For design, RFCs, or competing hypotheses. Not for a single-file edit. Start one worker per member, named `<team>-<role or hypothesis>`. Prime each member. Each writes `<role>.md`. The orchestrator checks the claims and writes one answer. No majority vote.

**Isolated reviewer.** For an adversarial gate, or when each review must load fat style skills plus `AGENTS.md`. Not for one or two reviews, or when review is only "matches the brief." Use Gemini 4 Neon, Opus 5.5, or Sol 6.1, never `pi`. Spawn it when the first implement unit lands. Prime it, and tell it to load the stack style skills, read `AGENTS.md` on the touched paths, write `review.md`, and stop. The orchestrator reads `review.md` and never loads the style corpus.

**Review each stack apart.** A diff over backend and frontend gets one review unit per stack, never one review of the mixed diff. Each unit loads its stack's style skills and reads every `AGENTS.md` from the repo root down to each touched path. A data stack (dbt, Python, warehouse SQL) is a stack of its own.

## Guardrails

- Do not use Claude's experimental in-process agent teams. herdr-core terminals let claude, codex, agy, and pi share one team.
- An orchestrator that ends with idle workers has not finished. Clean up first.
