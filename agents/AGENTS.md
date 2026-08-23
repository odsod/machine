# Global Agent Instructions

Agents must follow these instructions in all projects.

## Style

Warm, familiar, honest, direct. Warmth is stance, not filler.

Write in [ASD-STE100](https://asd-ste100.org/) Simplified Technical English:
short sentences, active voice, one idea each, plain approved verbs
(do/start/use, not perform/initiate/enable).

Chat: complete sentences; lead with the answer.
Files: headers and bullets; no intros or conclusions.

No em dashes. No LLM tells. If it reads like a press release, rewrite it flatter.

## Behavior

Bias to caution over speed. Skip this section for trivial tasks.

- Unclear or several readings: stop, name the gap, ask. Don't pick silently.
- Prefer the simpler approach; say so when the user is overbuilding.
- Minimum code that solves the ask. Nothing speculative.
- Every changed line traces to the request. Match existing style.
  Clean up only orphans you created.
- Define a check, then loop until it passes. Bugs: failing check first.

## Tools

Dev tools: mise via `odsod/machine` (`~/.local/share/mise/` shims). Don't install around it.

Prefer: `rg` not grep, `fd` not find, `uv` not pip, `oxfmt` for JS/TS/JSON/YAML/HTML/CSS/MD,
`magick`/`identify` for images. Timing: `hyperfine`. JWTs: `jwt decode`.

Web: `defuddle parse <url> --md --frontmatter -l en` first.
Interactive/auth: `agent-browser-odsod connect`, then `agent-browser open|read|click`.

`gh` always `-R <owner>/<repo>` (jj workspaces have no git remotes).
Owner/repo from `~/Code/<host>/<owner>/<repo>`,
`~/Workspaces/<host>/<owner>/<repo>/<branch>`, or `jj git remote list`.

Terminal mux is Herdr (`HERDR_ENV=1`). Load `/herdr` only when asked to inspect panes.

## Skills

`AGENTS.md` and `.agents/skills/` are the real files everywhere. Each per-agent
name is a symlink onto them, never a second copy: `CLAUDE.md` → `AGENTS.md`,
`.claude/skills` → `.agents/skills`. Read and edit the `.agents` path.

`~/.agents/skills/` holds only skills that apply in every repo, and only `herdr`
qualifies. A skill about one repo belongs in that repo's own `.agents/skills/`.
Install a skill where it is needed rather than everywhere.

## Version control

Primary: `jj`. Use `git` only in repos with no `.jj`.
Always pass `-m` to describe/split/commit/squash: no `-m` opens an editor and hangs.
Never merge unless asked.

- No remote writes without asking. Reads are fine.
- Never reply to PR review comments. Title/body only (`gh pr edit`).
- Commits: Conventional Commits, subject ≤60. Body: why + what, 3–5 bullets, wrap 80.
- Data loss: recover from `jj op log`, never reimplement. Hooks snapshot every turn.
  Before long ops with no agent turn (`jj git fetch`, builds): `jj st`.
- Don't commit binaries. `rm` debug builds; `file` untracked files before commit.

### Modern jj

Older jj knowledge is wrong on these. Never guess a flag; the installed binary
documents itself. `jj help -k revsets|filesets|bookmarks|templates|config|glossary`
for the languages, `jj <cmd> --help` for a command.

- `jj bookmark`, not `jj branch`. Bookmarks are pointers, not checkout targets.
- `-o`/`--onto`, not `-d`/`--destination`.
- `jj op revert <op>` reverts one operation. `jj op undo` is gone. Plain `jj undo`
  is sequential: a second call undoes the second-to-last operation. `jj redo` exists.
- Revsets and filesets read a bare pattern as a glob. Use `exact:main` to pin.
- `diff_lines()`, not `diff_contains()`. No `all:` modifier; use `visible_heads()`.
- Repos are colocated by default: `.jj/` and `.git/` both exist.

### PR lifecycle

1. `jj git fetch --remote origin`, then `jj rebase -o main@origin` if the stack
   is behind trunk.
2. Fix every broken commit before anything else:
   `jj log -r 'mutable() & descendants(main@origin+) & (conflicts() | divergent() | (~empty() & description(exact:"")))'`.
   Conflicts → `jj resolve -r <rev>`. Divergent → `jj abandon <obsolete>`.
   Empty description → `jj describe -r <rev> -m "<subject>"`.
3. Read each diff. Split mixed commits: `jj split -r <rev> <paths> -m "<subject>"`.
4. `jj bookmark set <name> -r <tip>`, `jj git push --bookmark <name>`, `gh pr create`.
5. `jj new @` after the push. Never `jj new main@origin`: that drops back to
   trunk and hides the branch's files.
6. Delete temporary helper scripts first. Never push with unchecked "Test plan"
   boxes: finish them or remove the section.
7. Watch CI: `gh pr checks <pr> -R <owner>/<repo>` every 60s until nothing is
   pending. On red read only the failed check, with
   `gh run view <run-id> -R <owner>/<repo> --log-failed` or
   `gcloud builds log <build-id> | tail -80`. Fix, push, watch again.

## Layout

| Directory      | Purpose       | Naming                         |
| -------------- | ------------- | ------------------------------ |
| `~/Code`       | jj originals  | `<host>/<org>/<repo>`          |
| `~/Workspaces` | jj workspaces | `<host>/<org>/<repo>/<branch>` |
| `~/Activities` | no end date   | `<name>`                       |
| `~/Projects`   | time-limited  | `<YYYY-MM-DD>-<name>`          |
| `~/Vaults`     | Obsidian      | `<name>`                       |

| Path                                     | Purpose                   |
| ---------------------------------------- | ------------------------- |
| `~/Code/github.com/odsod/machine`        | provisioning              |
| `~/Code/github.com/odsod/machine/agents` | this file + global skills |

- `~/.agents` → `machine/agents`. Part of `machine`; commit changes there.
- `~/Vaults` is Syncthing, not git. Never init a repo there.
- Day-job repos and their cross-repo release flow: see that repo's own `AGENTS.md`.

## Vault

`~/Vaults/odsod`. Schema: that vault's `AGENTS.md`.

- "check the vault" → `obsidian vault="odsod" search query="..."`. Read `summary:` first.
- "update the vault" → ingest workflow in that `AGENTS.md`.
- "save this to the vault" → write `~/Vaults/odsod/inbox/<slug>.md`. Descriptive
  slug, no dates; ingest adds metadata. Web source: `defuddle parse <url> --md -o`
  that path, then add `title`, `url` and `captured` frontmatter. Save only on an
  explicit ask, and only if the content still helps in another project or month.
