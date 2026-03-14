#!/usr/bin/env python3

from __future__ import annotations

import argparse
import difflib
import os
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


BARE_KEY_RE = re.compile(r"^[A-Za-z0-9_-]+$")


def load_toml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open("rb") as handle:
        data = tomllib.load(handle)
    if not isinstance(data, dict):
        raise TypeError(f"{path} did not parse to a TOML table")
    return data


def format_key(key: str) -> str:
    if BARE_KEY_RE.match(key):
        return key
    escaped = key.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def format_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def format_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return format_string(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    if isinstance(value, list):
        return f"[{', '.join(format_value(item) for item in value)}]"
    raise TypeError(f"unsupported TOML value: {type(value).__name__}")


def dump_table(name: tuple[str, ...], table: dict[str, Any], out: list[str]) -> None:
    scalars: list[tuple[str, Any]] = []
    subtables: list[tuple[str, dict[str, Any]]] = []

    for key, value in table.items():
        if isinstance(value, dict):
            subtables.append((key, value))
        else:
            scalars.append((key, value))

    emit_header = bool(name and scalars)

    if emit_header:
        out.append(f"[{'.'.join(format_key(part) for part in name)}]")

    for key, value in scalars:
        out.append(f"{format_key(key)} = {format_value(value)}")

    if emit_header and subtables:
        out.append("")

    for index, (key, subtable) in enumerate(subtables):
        dump_table((*name, key), subtable, out)
        if index != len(subtables) - 1:
            out.append("")


def dump_toml(data: dict[str, Any]) -> str:
    lines: list[str] = []
    dump_table((), data, lines)
    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines) + "\n"


def merge_configs(base: dict[str, Any], target: dict[str, Any]) -> dict[str, Any]:
    merged = dict(base)
    if "projects" in target:
        projects = target["projects"]
        if not isinstance(projects, dict):
            raise TypeError("target projects table must be a TOML table")
        merged["projects"] = projects
    return merged


def synced_text(base_path: Path, target_path: Path) -> str:
    base = load_toml(base_path)
    target = load_toml(target_path)
    merged = merge_configs(base, target)
    return dump_toml(merged)


def cmd_sync(base_path: Path, target_path: Path) -> int:
    text = synced_text(base_path, target_path)
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(text, encoding="utf-8")
    print(f"[codex] Synced {target_path}")
    return 0


def cmd_diff(base_path: Path, target_path: Path) -> int:
    current = target_path.read_text(encoding="utf-8") if target_path.exists() else ""
    expected = synced_text(base_path, target_path)
    diff = difflib.unified_diff(
        current.splitlines(),
        expected.splitlines(),
        fromfile=str(target_path),
        tofile=f"{target_path} (synced)",
        lineterm="",
    )
    wrote_output = False
    for line in diff:
        print(line)
        wrote_output = True
    if not wrote_output:
        print(f"[codex] {target_path} is already in sync")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("sync", "diff"))
    parser.add_argument("--base", required=True)
    parser.add_argument("--target", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    base_path = Path(os.path.expanduser(args.base))
    target_path = Path(os.path.expanduser(args.target))

    if args.command == "sync":
        return cmd_sync(base_path, target_path)
    return cmd_diff(base_path, target_path)


if __name__ == "__main__":
    sys.exit(main())
