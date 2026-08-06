#!/usr/bin/env bash
if ! command -v herdr >/dev/null 2>&1; then
    exec "$SHELL"
fi
exec herdr
