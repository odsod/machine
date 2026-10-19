#!/usr/bin/env bash
set -euo pipefail

format_file() {
  local file="${1:-}"
  [ -n "$file" ] && [ -f "$file" ] || return 0
  case "$file" in
  *.go) gofumpt -w "$file" >/dev/null 2>&1 || true ;;
  *.py | *.pyi) ruff format --quiet "$file" >/dev/null 2>&1 || true ;;
  *.js | *.jsx | *.ts | *.tsx | *.mjs | *.cjs | *.json | *.jsonc | *.yaml | *.yml | *.toml | *.html | *.css | *.scss | *.md | *.mdx)
    oxfmt --write "$file" >/dev/null 2>&1 || true
    ;;
  *.lua) stylua --indent-type Spaces --indent-width 2 "$file" >/dev/null 2>&1 || true ;;
  *.sh | *.bash) shfmt -w -i 2 "$file" >/dev/null 2>&1 || true ;;
  *.tf | *.tfvars) terraform fmt "$file" >/dev/null 2>&1 || true ;;
  *.proto) buf format -w "$file" >/dev/null 2>&1 || true ;;
  esac
}

payload="$(cat)"
[ -n "$payload" ] || exit 0

path="$(printf '%s\n' "$payload" | jq -r '
  .tool_input.file_path //
  .file_path //
  .toolCall.args.TargetFile //
  empty
' 2>/dev/null || true)"

if [ -n "$path" ]; then
  format_file "$path"
  exit 0
fi

patch="$(printf '%s\n' "$payload" | jq -r '
  if (.tool_input | type) == "string" then .tool_input
  else .tool_input.patch // .tool_input.input // empty
  end
' 2>/dev/null || true)"
[ -n "$patch" ] || exit 0

cwd="$(printf '%s\n' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  case "$rel" in
  /*) file="$rel" ;;
  *) file="${cwd:+$cwd/}$rel" ;;
  esac
  format_file "$file"
done < <(
  printf '%s\n' "$patch" |
    sed -n 's/^\*\*\* \(Update\|Add\) File: //p; s/^\*\*\* Move to: //p' |
    sort -u
)
