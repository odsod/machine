#!/bin/sh
# Agent completion: bell + refresh jj status (matches codex notify / claude Stop hooks).
bell
test -d .jj && jj st >/dev/null 2>&1 || true
