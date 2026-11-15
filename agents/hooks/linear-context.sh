#!/usr/bin/env bash
# Session-start hook: refresh the nearest .linear-context.md from Linear and
# print it as agent context. The frontmatter names the Linear items; the body
# is generated. On a failed fetch, keep and print the old file.
#
# Usage: linear-context.sh [--agy]
#   --agy  print agy's {"inject_steps": [...]} JSON instead of plain markdown.
set -uo pipefail

name=.linear-context.md

cwd=$PWD
if [ ! -t 0 ]; then
  in_cwd=$(jq -r '.cwd // empty' 2>/dev/null || true)
  [ -n "$in_cwd" ] && cwd=$in_cwd
fi

file=
dir=$cwd
while :; do
  if [ -f "$dir/$name" ]; then
    file=$dir/$name
    break
  fi
  [ "$dir" = / ] && break
  dir=$(dirname "$dir")
done
[ -n "$file" ] || exit 0

emit() {
  if [ "${1:-}" = --agy ]; then
    jq -n --rawfile body "$file" '{inject_steps: [{ephemeral_message: $body}]}'
  else
    cat "$file"
  fi
}

project=$(yq --front-matter=extract '.linear.project // ""' "$file" 2>/dev/null)
mapfile -t issues < <(yq --front-matter=extract '.linear.issues // [] | .[]' "$file" 2>/dev/null)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pids=()
for i in "${!issues[@]}"; do
  timeout 10 linear issue view "${issues[$i]}" --no-pager --no-download --no-input \
    >"$tmp/issue-$i.md" 2>/dev/null &
  pids+=($!)
done
if [ -n "$project" ]; then
  timeout 10 linear project view "$project" --no-pager --no-input \
    >"$tmp/project.md" 2>/dev/null &
  pids+=($!)
  timeout 10 linear project-update list "$project" --limit 3 --no-input \
    >"$tmp/updates.md" 2>/dev/null &
  pids+=($!)
fi

ok=1
for pid in "${pids[@]}"; do
  wait "$pid" || ok=0
done

if [ "$ok" = 0 ]; then
  emit "$@"
  exit 0
fi

# Demote markdown headings one level, outside fenced code blocks.
demote() {
  awk '/^```/ { fence = !fence } !fence && /^#/ { $0 = "#" $0 } { print }' "$1"
}

{
  # yq prints the opening "---" itself.
  yq --front-matter=extract ".refreshed = \"$(date -Iseconds)\"" "$file"
  echo ---
  cat <<'EOF'

# Linear context

This workspace tracks the Linear items below. Use the /linear-cli skill to
work with them.

- When you start work on an issue, run
  `linear issue update <ID> --state started`.
- At each milestone and when you stop, post progress with
  `linear issue comment add <ID> --body-file <file>`.
- Link each PR to its issue with `linear issue link <ID> <PR URL>`.
- Do not set an issue to Done or Canceled. The user does that.
- A hook regenerates this file at session start. Do not edit the body. To
  change the tracked items, edit the `linear:` frontmatter.
EOF
  for i in "${!issues[@]}"; do
    echo
    demote "$tmp/issue-$i.md"
  done
  if [ -n "$project" ]; then
    echo
    demote "$tmp/project.md"
    echo
    echo "## Recent project updates"
    echo
    demote "$tmp/updates.md"
  fi
} >"$tmp/out" && cp "$tmp/out" "$file.tmp" && mv "$file.tmp" "$file"

emit "$@"
