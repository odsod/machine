#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

if ! command -v gum >/dev/null 2>&1; then
  exit 0
fi

if ! command -v smug >/dev/null 2>&1; then
  exit 0
fi

sessions="$(smug list | sed '/^[[:space:]]*$/d')"
if [[ -z "$sessions" ]]; then
  exit 0
fi

if ! selected="$(printf '%s\n' "$sessions" | gum choose --header "Start smug session")"; then
  exit 0
fi

if [[ -z "$selected" ]]; then
  exit 0
fi

config_path="$HOME/.config/smug/${selected}.yml"
if [[ ! -f "$config_path" ]]; then
  config_path="$HOME/.config/smug/${selected}.yaml"
fi

declare -a kv_args=()

if [[ -f "$config_path" ]]; then
  declare -A seen=()
  declare -a vars=()

  while IFS= read -r token; do
    inner="${token:2:${#token}-3}"
    name="${inner%%:-*}"
    if [[ -z "${seen[$name]+x}" ]]; then
      seen["$name"]=1
      vars+=("$name")
    fi
  done < <(grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*(:-[^}]*)?\}' "$config_path" || true)

  for name in "${vars[@]}"; do
    while true; do
      if ! value="$(gum input --header "$selected: $name" --placeholder "$name")"; then
        exit 0
      fi

      trimmed="${value//[[:space:]]/}"
      if [[ -n "$trimmed" ]]; then
        kv_args+=("$name=$value")
        break
      fi
    done
  done
fi

smug switch "$selected" "${kv_args[@]}"
