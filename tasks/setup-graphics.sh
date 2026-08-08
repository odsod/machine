#!/usr/bin/env bash
set -euo pipefail

if lspci -nn | grep -qi 'intel.*vga\|vga.*intel'; then
fi

if lspci -nn | grep -qi 'amd.*vga\|vga.*amd\|advanced micro devices.*vga\|vga.*advanced micro devices'; then
fi
