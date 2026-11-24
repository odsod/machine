# Global Agent Instructions

## Style

- Warm, familiar, honest, direct. Warmth is stance, not filler.
- Write [ASD-STE100](https://asd-ste100.org/) Simplified Technical English:
  short sentences, active voice, one idea each, plain verbs
  (`do`/`start`/`use`, not `perform`/`initiate`/`enable`).
- Chat: complete sentences; lead with the answer.
- Files: headers and bullets; no intros or conclusions.
- No em dashes, no LLM tells, no press-release tone.

## Behavior

- Bias to caution over speed. Skip these rules for trivial tasks.
- Unclear or multiple readings: stop, name the gap, ask. Never pick silently.
- Prefer the simpler approach; tell the user when they overbuild.
- Write minimum, non-speculative code. Trace every changed line to the request,
  match existing style, and clean up only orphans you created.
- Define a check and loop until it passes. For bugs, write a failing check
  first.

## Tools

- Dev tools come from `mise` via `odsod/machine` (`~/.local/share/mise/` shims).
  Never install around it.
- Prefer: `rg`, `fd`, `uv`, `oxfmt` (JS/TS/JSON/YAML/HTML/CSS/MD),
  `magick`/`identify`, `hyperfine`, `jwt decode`, `pdftotext`,
  `pdftoppm` + `tesseract`.
- Phone photos: `/nfs/media/Photos/Oscar's Pixel 9 Pro/` (NFS automount).
- Web: `defuddle parse <url> --md --frontmatter -l en` first. Interactive or
  auth sites: `agent-browser-odsod connect`, then
  `agent-browser open|read|click`.
- Public URL for a local port: `tailscale funnel --bg --https=8443 <port>`;
  stop with `tailscale funnel --https=8443 off`. Never `cloudflared` or `ngrok`.
- No cloud Artifacts: write repo deliverables where asked and temp files in
  `/tmp`.

## Herdr

- You run in a Herdr terminal (`spaces > tabs > panes`) on `herdr-core`;
  address is `$HC_TERMINAL_ID`. `herdr-app` changes the window; `hc` runs and
  talks to programs and agents.
- Your space:
  `herdr-app ls | jq -r --arg t "$HC_TERMINAL_ID" '.spaces[] | select(any(.tabs[].terminals[]; .terminal==$t)) | .id'`.
- New tab: `herdr-app do tab.new --space <your space> --name <name> --argv '[...]'`.
  Always pass `--space` (default is the selected space). Open tabs or splits
  only when asked or for child agents; close with
  `tab.close --id <id> --confirmed true`.
- A space is a workstream, a tab is a topic in it. Start child agents in a tab
  of your space, one tab per topic (two researchers share `research`), so the
  user can watch them:
  `hc run --bg --name <name> --label herdr.space=<your space> --label herdr.tab=<your space>-<topic> --cwd <dir> -- claude "<task>"`,
  then `herdr-app do tab.rename --id <your space>-<topic> --name <topic>`.
  The label sets the tab id (global across spaces), not its name. Run builds,
  tests and watchers hidden (no labels).
- Fork a new workstream without moving focus:
  `herdr-space start workspace <host>/<org>/<repo> <bookmark> --prompt "<task>"`
  (`--agent codex|agy|pi`, `--on <machine>`). `code <host>/<org>/<repo>` takes
  the repo only.
- Inspect window: `herdr-app shot /tmp/shot.png`, then read the PNG.
- Never stop or restart `herdr-core` or `herdr-app` unless asked. Never start a
  core from an agent shell (terminals inherit your env).
- More actions: read `herdr-app --skill` (window) or `hc --skill` (programs,
  agents) first. Multi-agent teams: load `/agent-team`.

### Images and drawings

- Show an image (Kitty graphics, not bash output):
  `herdr-app do tab.new --space <your space> --name <name> --argv '["sh","-c","chafa -f kitty <png>; read x"]'`.
  Shrink photos first: `magick <in> -auto-orient -resize 1600x1600 <out>`.
- Drawings: write Python for a to-scale SVG (real units, labels, legend),
  render with `magick -density 96 <svg> <png>`, check the PNG for overlaps,
  then show it.

## Skills

- `AGENTS.md` and `.agents/skills/` are the real files; `.claude/skills`
  symlinks to `.agents/skills`. Read and edit `.agents` paths.
- Put cross-repo skills in `~/.agents/skills/` and repo-specific skills in that
  repo's `.agents/skills/`.

## Version control

- Primary: `jj` (`git` only with no `.jj`). Repos are colocated (`.jj/` and
  `.git/`).
- Always pass `-m` to `describe`, `split`, `commit`, and `squash` (no `-m`
  hangs in an editor).
- Never write to remotes (push, PR create/edit, merge) without asking; reads
  are fine. Never reply to PR review comments; edit title and body only
  (`gh pr edit`).
- Commits: Conventional Commits, subject <=60 chars; body: why + what, 3-5
  bullets, wrap at 80.
- Data loss: recover from `jj op log`, never reimplement. Hooks snapshot each
  turn; run `jj st` before long ops (`jj git fetch`, builds).
- Never commit binaries (`jj` tracks untracked files): `rm` debug builds and
  run `file` on untracked files first.
- Always pass `-R <owner>/<repo>` to `gh` (jj workspaces have no git remotes)
  and `GH_REPO=<owner>/<repo>` to `gh stack`. Get `<owner>/<repo>` from
  `~/Code/<host>/<owner>/<repo>`,
  `~/Workspaces/<host>/<owner>/<repo>/<branch>`, or `jj git remote list`.

### Modern jj

- Never guess flags: check `jj <cmd> --help` or
  `jj help -k revsets|filesets|bookmarks|templates|config|glossary`.
- `jj bookmark` (not `jj branch`; pointers, not checkout targets). `-o`/`--onto`
  (not `-d`/`--destination`).
- `jj op revert <op>` reverts one op (`jj op undo` is gone). `jj undo` steps
  back sequentially; `jj redo` reverses it.
- Bare patterns in revsets and filesets are globs; use `exact:main` to pin.
- `diff_lines()` (not `diff_contains()`); `visible_heads()` (no `all:`).

### PRs and stacks

- Default to one PR (each PR reserves a CI runner); split commits, not PRs.
  Open a new PR only at a ship gate (work that must merge first: secrets,
  migration, pinned release) and name the gate in the PR body.
- Prepare before pushing:
  1. `jj git fetch --remote origin`, then `jj rebase -o main@origin` if behind
     trunk.
  2. Fix broken commits first:
     `jj log -r 'mutable() & descendants(main@origin+) & (conflicts() | divergent() | (~empty() & description(exact:"")))'`
     (`jj resolve -r <rev>`, `jj converge --no-interactive`,
     `jj describe -r <rev> -m "<subject>"`).
  3. Split mixed commits (`jj split -r <rev> <paths> -m "<subject>"`). Delete
     temp scripts; never push unchecked "Test plan" boxes.
- Publish (one bookmark per ship gate, bottom to top):
  ```sh
  jj log --reversed -r 'trunk()..@ & bookmarks()' --no-graph -T 'bookmarks ++ "\n"'
  jj bookmark set <name> -r <rev>
  jj git push --bookmark <bottom> --bookmark <top>
  gh pr create -R <owner>/<repo> --base main --head <bottom> --title <t> --body-file <p>
  gh pr create -R <owner>/<repo> --base <bottom> --head <top> --title <t> --body-file <p>
  GH_REPO=<owner>/<repo> gh stack link <bottom-pr> <top-pr>
  ```
- Pass PR numbers to `gh stack link`, never branch names (branch names push
  with git; `jj` owns pushes).
- Never run `gh stack init|add|submit|sync|rebase|view|modify` (they need an
  attached git HEAD). Only `link`, `merge`, and `unstack` are safe.
- Same gate: `jj bookmark set <top> -r @` and push. New gate:
  `jj bookmark create <new> -r @`, `jj git push --bookmark <new>`,
  `gh pr create`, then `gh stack link <top-pr> <new-pr>` (additive).
- Run `jj new @` after pushing. Never `jj new main@origin` (hides branch files).
- Watch CI: poll `gh pr checks <pr> -R <owner>/<repo>` every 60s until settled.
  On failure, read only the failed check
  (`gh run view <run-id> -R <owner>/<repo> --log-failed` or
  `gcloud builds log <build-id> | tail -80`), fix, push, and watch again.
- Merge stacks with `GH_REPO=<owner>/<repo> gh stack merge <pr> --yes --squash`
  (merges `<pr>` and unmerged PRs below; `gh pr merge` and auto-merge fail on
  stacks). With a merge queue, wait for `gh pr checks` first.
- After the bottom PR merges, GitHub rebases and retargets the next PR:
  `jj git fetch`, verify with `jj diff --from <name>@origin --to <name>`, take
  remote (`jj bookmark set <name> -r <name>@origin`), and abandon the local
  copy. Rebase locally only if GitHub did not.

## Layout

| Directory      | Purpose       | Naming                         |
| -------------- | ------------- | ------------------------------ |
| `~/Code`       | jj originals  | `<host>/<org>/<repo>`          |
| `~/Workspaces` | jj workspaces | `<host>/<org>/<repo>/<branch>` |

- `~/.agents` symlinks to `machine`'s `agents/` dir (this file and global
  skills); commit changes there.
- Non-code work (research, documents, one-off tasks) goes in a central repo
  below, never in loose folders.
- Day-job repos and their cross-repo release flow: see that repo's own
  `AGENTS.md`.

## Central repos

The user names these repos by short name ("check the house repo", "put this in
my brain"). Each lives at `~/Code/<path>` and has its own `AGENTS.md`: read it
before you work there. If a clone is missing, run
`jj git clone <url> ~/Code/<path>`.

| Name      | Path                       | Holds                                                         |
| --------- | -------------------------- | ------------------------------------------------------------- |
| `machine` | `github.com/odsod/machine` | Machine provisioning, global agent rules, skills              |
| `daemon`  | `github.com/odsod/daemon`  | System daemon for the workflow: recorder, keys, KDE shortcuts |
| `brain`   | `git.lan/odsod/brain`      | Second brain (Obsidian vault)                                 |
| `house`   | `git.lan/odsod/house`      | The house: systems, hosts, documents, procedures              |
| `company` | `git.lan/odsod/company`    | The user's own company vault                                  |

- Small or limited edits you make yourself: work in the original
  `~/Code/<path>`, also when one task edits several of these repos.
- Work forked off to a new autonomous agent ("start a new `<name>`
  workspace"): run
  `herdr-space start workspace <path> <bookmark> --prompt "<task>"`. It makes
  the jj workspace `~/Workspaces/<path>/<bookmark>` and opens a new space with
  the agent in it. Name the bookmark after the task; ask if the task is
  unclear.
- "check `<name>`": search that repo with `rg`; in `brain`, use
  `obsidian vault="brain" search query="..."` and read `summary:` first.
- "put this in `<name>`" or "save this to `<name>`" (`brain`, `house`,
  `company`): write `~/Code/<path>/inbox/<slug>.md` (descriptive slug, no
  dates). For web pages, run `defuddle parse <url> --md -o <path>`, then add
  `title`, `url`, and `captured` frontmatter. Save only on an explicit ask.
- "update `<name>`": `jj git fetch` and rebase first, follow the ingest or
  change workflow in its `AGENTS.md`, then commit and open a PR. Never push
  `main`.
- `brain`: the `daemon` recorder writes into it; commit recorder output with
  your ingest. `main` merges fast-forward only; see its "Commit format".
