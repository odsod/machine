---
name: agent-team
description: "Compose a Herdr team that works until an outcome is realized, or decide this pane can realize it alone. Use when the user invokes /agent-team, asks to set up an agent team, orchestrate a sibling pane, assign work across claude, agy, pi, or cursor, or when a smart agent on a long plan should offload mechanical work to preserve its own context. Do not use for a trivial one-file edit, and do not use merely to inspect panes (that is /herdr). Requires HERDR_ENV=1."
---

# Agent Team

A team is live agents plus a brief, working until an outcome is realized. The outcome is an end state, not a work list; stop when the done-when check passes. Handoff and waiting are implied. Do not freeze standing roles. Pick harnesses and responsibilities for this outcome, agree them, then run.

The invoking agent is the **orchestrator** unless the user names someone else. It stays in this pane. A team is optional: execute alone and load this skill only when a unit is worth delegating.

**Who loads this skill.** Prime agents that must judge or coordinate: orchestrator, design, review, write, council. Do not prime pure execution. Implement, bulk, and fast-model verify work in a vacuum: one unit, an output path, a stop. They never see `/agent-team`, the roster, or the brief's protocol. The orchestrator holds the protocol for them.

Load `/herdr` for CLI details.

## How many agents

Two dimensions. Headcount is what they require, not a chart to fill.

**Capability.** Does this unit need long-horizon design, careful review, fast coding, multimodal or parallel process, succinct docs, or a different frame? If this pane already can, do not add an agent for capability alone.

**Context.** Will doing the unit here leave the orchestrator able to hold the plan? If it would fill the window with diffs, style corpora, dumps, or bulk files, give it to another pane even when this model could do the work. Keep own context fit for the horizon.

Window size is part of that duty. Opus 5 is 1M; Grok 4.6 is 256k. For real long-horizon work, orchestrate on Opus 5 so less is lost to compact and continuity holds. Use Grok 4.6 to lead only when a different frame matters more than window.

Add an agent when either dimension fails here. Add none when both pass. Drop or `/clear` a worker when its dimension is done.

## Roster

| Kind     | Default model             | Give it                                                | Do not give it alone                    | Context reset                         |
| -------- | ------------------------- | ------------------------------------------------------ | --------------------------------------- | ------------------------------------- |
| `claude` | Opus 5                    | orchestrate, design, architecture, careful review      | bulk or multimodal grind                | `/compact`, then `/clear`             |
| `agy`    | Gemini 3.7 Flash (Medium) | throughput, parallel subagents, multimodal, large text | unsupervised design or merge            | `/clear` only (no user compact)       |
| `pi`     | DeepSeek V4 Flash         | fast coding; quality is OK with a reviewer             | design or review without a second agent | `/new`                                |
| `cursor` | Grok 4.6                  | write; lead when Opus is wordy or stuck in one frame   | long-horizon orchestrate                | restart the agent if the pane is junk |
| `cursor` | Composer 2.5              | fast coding, tighter than DeepSeek V4 Flash            | architecture                            | restart the agent if the pane is junk |

`--kind` from the Kind column. Native model args only after `--` when live help documents them. This machine already pins Claude → Opus 5, agy → Gemini 3.7 Flash Medium, pi → DeepSeek V4 Flash.

- Default: Opus 5 orchestrates; this pane keeps design and review; pi takes mechanical implement when it would burn that window.
- Write (`AGENTS.md`, API docs): Grok 4.6.
- Different frame: Grok 4.6 may lead a slice; do not move the whole horizon onto 256k unless the user wants that trade. Tighter coder: Composer 2.5 implements.
- Bulk, multimodal, or corpus: agy fans out; orchestrator reads `report.md` only.
- Repeated style-heavy review: isolated reviewer (Opus or Grok 4.6). See below.

## Responsibilities

Assign these. They are not agent types. One agent may hold several. An outcome may need only some.

| Responsibility | Owns                                                                                                      | Does not own unless assigned    |
| -------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------- |
| orchestrate    | Brief, keep vs delegate, own context fit for the horizon, signals, escalate, declare the outcome realized | Implementation it chose to keep |
| design         | Shape, constraints, plan, what good looks like                                                            | Shipping the code               |
| implement      | Code and tests in scope                                                                                   | Redefining the outcome          |
| review         | Adversarial read against the brief and repo rules                                                         |                                 |
| write          | High-impact docs for humans and agents (`AGENTS.md`, API docs)                                            | Implementation or architecture  |
| verify         | Run the check; browser / user path / multimodal proof                                                     | Expanding scope                 |
| bulk           | Large-surface read or transform, including parallel multimodal                                            | Architecture                    |

**write:** short sentences, one idea each, plain verbs, no padding. Token-efficient. Match repo `AGENTS.md` style. Grok 4.6 unless this pane already is.

## Preconditions

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say you are not inside Herdr and stop. Discover pane and agent IDs per `/herdr`. Write them into the brief once. Do not re-resolve.

## Flow

### 1. Compose, then agree

Propose, then wait. Do not spawn first. Members may be this pane only.

- Outcome in one paragraph (what will be true)
- Capability and context budget per unit
- Keep vs delegate
- Workers only if a unit needs them (`impl`, `review`, `write`, `scan`; names `[a-z][a-z0-9_-]{0,31}`, unique)
- Done-when: an exact command or proof that the outcome holds

Do not name or start a worker until you have a unit for it. Do not spawn until Done when is a command or proof this pane can run without the worker. If the outcome is still a question, ask; do not staff.

### 2. Write the brief

Dir: `/tmp/agent-team/<slug>/`. Never the repo. Brief: `brief.md`. Findings: `<name>.md` in that dir.

```bash
mkdir -p /tmp/agent-team/<slug>
```

First prompt: primed agents load `/agent-team`, their name, path to the brief. Execution agents get the unit, the output path, and stop. No skill, no brief dump.

```markdown
# Team: <slug>

Outcome: …
Done when: <command or proof that it holds>

## Members

- orchestrator <pane-id> claude/opus-5 orchestrate, design, review
- impl <pane-id> pi/deepseek-v4 implement # omit until you delegate

## Units

- design: keep
- implement: delegate
- review: keep

## Handoff

- worker tokens: PHASE_COMPLETE | BLOCKED
- (append-only; orchestrator decisions in prose)
```

A delegated unit gets at most two fix cycles. Count them from the orchestrator prose lines.

### 3. Spawn when you delegate

Skip while this pane is doing the unit. Skip until Done when is runnable.

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr agent start impl --kind pi --pane <pane-id>
herdr agent prompt impl "Implement <unit>. Write /tmp/agent-team/<slug>/impl.md. Stop when done." --wait --timeout 120000
```

For a primed sibling (review, write, council), first prompt is: load `/agent-team`, your name, path to `brief.md`. Wait.

Split a wide pane right, a tall pane down. Reuse an idle sibling of the right kind. Native model args only after `--`, and only if live `herdr agent start` help lists them. Do not create a workspace, tab, or worktree unless asked.

### 4. Run

For each unit: do it here, or prompt a worker.

A primed worker follows this skill: one unit, findings file, `PHASE_COMPLETE` or `BLOCKED` on Handoff, **stop**.

An execution worker does not. Give it the unit, `/tmp/agent-team/<slug>/<name>.md`, and stop. Do not mention this skill or Handoff tokens. After `--wait`, the orchestrator checks the file (and the test), then appends the Handoff line itself.

`--wait` is not a finished unit. It can return while the agent is still on an alternate screen, or sit on `working` after the artifact exists. A unit is finished when: findings file written, or the agreed check passed, or a token in Handoff. After `--wait`, read those; if needed `herdr agent get` / `herdr agent read --source visible`.

Review the diff and the check, not the worker's claims. Then prompt the next unit, or send notes via the findings file. Append a prose Handoff line (`orchestrator → impl: fix cycle 1, see impl.md`) so a restart can tell reviewed from unreviewed and count fix cycles.

Unclear → open question in the brief, do not invent. Same handoff fails twice → ask the user. Only the orchestrator declares the outcome realized.

Implementer may make local `jj` commits. Nobody pushes unless asked.

## Shapes

Default is above: solo, then maybe an implement sibling.

**Council.** Prime them. N parallel panes. Each writes `/tmp/agent-team/<slug>/<name>.md`. Orchestrator reads, checks claims, synthesizes one answer. No majority vote. For design, RFC, or competing hypotheses. Not a single-file edit.

**Agy vacuum.** Orchestrator keeps the question and the bar. Agy does not load this skill. Fan Flash subagents over a large corpus. Orchestrator reads only `/tmp/agent-team/<slug>/report.md`. When the corpus would blow this window. Short units; `/clear` between them.

**Isolated reviewer.** When each cycle must reload fat style skills plus `AGENTS.md`, or the implementer is a fast model that needs a real gate. Reviewer is Opus or Grok 4.6, not pi or agy. Prime it with this skill. Spawn when the first implement unit lands. Load this skill and the stack style skill, read `AGENTS.md` on the touched path, write `review.md`, token `PHASE_COMPLETE` or `BLOCKED`, stop. Orchestrator reads `review.md`; it does not ingest the style corpus. Not for one or two reviews, and not when review is only "matches the brief."

## Guardrails

- Do not spawn, and do not start a delegated unit, until Done when is a command or proof this pane can run without the worker. If the outcome is still an open question, ask. Do not staff a team to invent it.
- Do not use Claude's experimental in-process agent teams. This protocol is Herdr panes so pi, agy, and cursor can sit on the same team.
- Agy has no user compact: keep its units short and `/clear` between them.
- After a restart: `herdr agent list`, read the brief, continue from Handoff.
- Fast models (agy, pi, Composer): vacuum. One tight unit, an output path, a stop. Do not load this skill into those panes.
