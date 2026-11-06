---
name: agent-team
description: "Compose the agent team of this Herdr workspace that works until an outcome is realized, or decide this pane can realize it alone. Use when the user invokes /agent-team, asks to set up an agent team, orchestrate a sibling pane, assign work across claude, codex, agy, or pi, or when a smart agent on a long plan should offload mechanical work to preserve its own context. Do not use for a trivial one-file edit, and do not use merely to inspect panes (that is /herdr). Requires HERDR_ENV=1."
---

# Agent Team

An agent team is live agents in Herdr panes plus a brief, working until an outcome is realized. The outcome is an end state, not a work list. Stop when the done-when check passes. Pick harnesses and responsibilities for this outcome, agree them, then run. Do not freeze standing assignments.

The invoking agent is the **orchestrator** unless the user names someone else. It stays in this pane. A team is optional: work alone, and delegate only a unit that is worth it. Load `/herdr` for CLI details.

**One team per workspace.** Each Herdr workspace has a name (its label) and holds at most one agent team. The team has the same name as the workspace. Never give the team a name of its own, and never start a second team in a workspace. Team agents stay in its workspace.

**Pane IDs, labels, and roles.** Each member has three handles:

| Handle     | Example          | Use it for                                   |
| ---------- | ---------------- | -------------------------------------------- |
| Pane ID    | `wDR:p2`         | Every `herdr agent` and `herdr pane` command |
| Pane label | `Implement (pi)` | Display only: what the pane does, then kind  |
| Role       | `impl`           | Findings file name, brief, Handoff lines     |

- Target agents by pane ID only. Pane IDs are unique on the server and never reused.
- Agent names are unique across all workspaces, so a name like `impl` collides with other teams. `herdr agent start` needs a name: derive it from the pane ID (`wDR:p2` → `wdr-p2`).
- Label every pane right after you create it, and write its pane ID into the brief.
- Roles match `[a-z][a-z0-9_-]{0,31}` and are unique in the team.

**Primed vs vacuum.** Prime agents that judge or coordinate (orchestrate, design, review, write, council): their first prompt is load `/agent-team`, their role, and the brief path. Everything else works in a vacuum: one unit, an output path, a stop. Never show a vacuum agent this skill, the brief, or Handoff tokens. The orchestrator holds the protocol for it.

## When to add an agent

Add an agent only when this pane fails one of two tests:

- **Capability.** The unit needs something this pane lacks: grind (implement, refactor, run tests), multimodal or parallel work, web research, or a different frame.
- **Context.** Doing the unit here would fill this window with diffs, style corpora, dumps, or bulk files, and leave it unable to hold the plan.

Close a worker as soon as its last unit is accepted.

## Roster

| Kind     | Default model           | Give it                                                                | Do not give it alone                    | Context reset             |
| -------- | ----------------------- | ---------------------------------------------------------------------- | --------------------------------------- | ------------------------- |
| `claude` | Opus 5.5                | orchestrate, design, architecture                                      | bulk or multimodal grind                | `/compact`, then `/clear` |
| `codex`  | Sol 6.1                 | fallback for Opus 5.5 (unavailable, rate-limited, or stuck)            | bulk or multimodal grind                | `/compact`, then `/new`   |
| `agy`    | Gemini 4 Argon (Medium) | write, adversarial review, multimodal or large corpus (fans subagents) | long-horizon orchestrate or merge       | `/compact`, then `/clear` |
| `agy`    | Gemini 3.8 Flash        | web research                                                           | design, review, or write                | `/compact`, then `/clear` |
| `pi`     | DeepSeek V4.1 Flash     | grind: implement, refactor, run tests and smoke tests                  | design or review without a second agent | `/new`                    |

Default team: Opus 5.5 orchestrates and designs, `pi` does the grind (implement, refactor, tests), Gemini 4 Argon reviews and writes, Gemini 3.8 Flash does web research.

`--kind` from the Kind column. This machine pins each kind to its first model above. For Gemini 3.8 Flash, start agy with `-- --model gemini-3.8-flash-medium`. Pass other native args after `--` only when live `herdr agent start` help lists them.

For bulk and web research, agy writes `report.md` and the orchestrator reads only that file.

Responsibilities do not cross unless assigned: design does not ship code, implement does not redefine the outcome, write does not touch implementation or architecture, verify does not expand scope, bulk does not touch architecture. Write output is short sentences in the repo `AGENTS.md` style.

## Flow

### 1. Set up

```bash
test "${HERDR_ENV:-}" = 1 || echo "not in Herdr"
team="$(herdr workspace get "$HERDR_WORKSPACE_ID" | jq -r .result.workspace.label)"
test -f "/tmp/agent-team/$team/brief.md" && echo "team exists"
herdr pane rename "$HERDR_PANE_ID" "Orchestrator (<kind>)"
```

- Not in Herdr: say so and stop.
- No label: name the workspace for the outcome (short, lowercase, like `auth-refactor`) with `herdr workspace rename "$HERDR_WORKSPACE_ID" <name>`, and use that as `team`.
- Brief exists and Handoff does not end with `orchestrator: team closed`: a live team exists. Continue it from Handoff. A closed team's brief: write a new one over it.

### 2. Propose, then agree

Propose, then wait for the user. Members may be this pane only.

- Outcome in one paragraph (what will be true)
- Units, with keep or delegate, and the capability or context reason
- Workers for delegated units only, each with a role and a pane label
- Done when: an exact command or proof that this pane can run without the worker

If the outcome is still a question, ask. Do not staff a team to invent it.

### 3. Write the brief

Write `/tmp/agent-team/<team>/brief.md`, never in the repo. Findings go to `<role>.md` in the same dir.

```markdown
# Team: <team>

Workspace: <workspace-id>

Outcome: …
Done when: <command or proof that it holds>

## Members

<!-- role | pane ID | pane label | harness/model | responsibilities -->

- orchestrator | wDR:p1 | Orchestrator (claude) | claude/opus-5.5 | orchestrate, design
- impl | <pane-id> | Implement (pi) | pi/deepseek-v4.1-flash | implement # add when you delegate

## Units

- design: keep
- implement: delegate

## Handoff

- worker tokens: PHASE_COMPLETE | BLOCKED
- (append-only; orchestrator decisions in prose)
```

### 4. Spawn when you delegate

Spawn a worker only when its unit is next. Reuse an idle sibling of the right kind. Do not create a workspace or worktree unless the user asks.

Layout: split this tab for 1 or 2 workers (right for a wide pane, down for a tall one). Use a new tab when splits get too narrow, or for a group such as a council.

```bash
# Same tab:
pane="$(herdr pane split --current --direction right --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)"
# New tab (always pass --workspace, or Herdr uses the focused workspace):
pane="$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --label "<tab label>" --cwd "$PWD" --no-focus | jq -r .result.root_pane.pane_id)"

herdr pane rename "$pane" "Implement (pi)"
herdr agent start "$(echo "$pane" | tr 'A-Z:' 'a-z-')" --kind pi --pane "$pane"
herdr agent prompt "$pane" "Implement <unit>. Write /tmp/agent-team/<team>/impl.md. Stop when done." --wait --until working --until blocked --timeout 10000
herdr agent wait "$pane" --timeout <ms that fit the unit>
```

`--until working` only confirms the agent started; `agent wait` waits for the unit. A prompt sent right after `agent start` often stalls (`agent_prompt_stalled`). A stall does not prove the prompt was lost, so read the screen (`herdr agent read "$pane" --source visible`) before you act:

- Input box empty and agent `idle`: resend once.
- Prompt text still in the input box: `herdr agent send-keys "$pane" enter`.
- `working`: continue to `agent wait`.
- `blocked`: read the dialog and ask the user.

Still stalled after one resend: tell the user.

### 5. Run

A unit is finished when its findings file exists, the agreed check passes, or a primed worker writes a token to Handoff. `agent wait` returning is not enough: it tracks state, not a turn, and an `idle` agy can still have subagents running.

- Review the diff and the check, not the worker's claims.
- Append a prose Handoff line for each decision (`orchestrator → impl: fix cycle 1, see impl.md`). A restart uses these to tell reviewed from unreviewed work.
- A delegated unit gets at most two fix cycles. Then ask the user.
- Unclear: write an open question in the brief. Do not invent.
- Workers may make local `jj` commits. Nobody pushes unless asked.
- Only the orchestrator declares the outcome realized.
- After a restart: read the brief, check its pane IDs with `herdr pane list --workspace "$HERDR_WORKSPACE_ID"`, continue from Handoff.

### 6. Clean up

The outcome is not realized while the team still runs. Clean up yourself before the final report:

- Close every pane and tab the team created. Then check that `herdr pane list --workspace "$HERDR_WORKSPACE_ID"` shows only the panes the user had before.
- Worker jj workspaces: check that each worker's commits are in the stack (`jj log -r '<ws>@- & ~::<tip>'` is empty), then `jj workspace forget <ws>` and remove the directory.
- Stop dev servers and other long processes the team started, unless the user needs them next. Say which ones you left running, and why.
- Append `orchestrator: team closed` to Handoff.

Something you cannot close safely (unique work, a process the user owns): name it in the final report, with the command to close it.

## Shapes

**Council.** For design, RFCs, or competing hypotheses. Not for a single-file edit. Make a `council` tab, split its root pane once per member, and label each pane by role or hypothesis. Prime each member. Each writes `<role>.md`. The orchestrator checks the claims and writes one answer. No majority vote.

**Isolated reviewer.** For an adversarial gate, or when each review must load fat style skills plus `AGENTS.md`. Not for one or two reviews, or when review is only "matches the brief." Use Gemini 4 Argon, Opus 5.5, or Sol 6.1, never `pi`. Spawn it when the first implement unit lands. Prime it, and tell it to load the stack style skills, read `AGENTS.md` on the touched paths, write `review.md`, and stop. The orchestrator reads `review.md` and never loads the style corpus.

**Review each stack apart.** A diff over backend and frontend gets one review unit per stack, never one review of the mixed diff. Each unit loads its stack's style skills and reads every `AGENTS.md` from the repo root down to each touched path. A data stack (dbt, Python, warehouse SQL) is a stack of its own.

## Guardrails

- Do not use Claude's experimental in-process agent teams. Herdr panes let claude, codex, agy, and pi share one team.
- An orchestrator that ends with idle workers has not finished. Clean up first.
