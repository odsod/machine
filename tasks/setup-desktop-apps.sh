#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="$HOME/.local/share/odsod/machine/data"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- Slack ---
SLACK_VERSION="4.51.180"
SLACK_BUILD="4.51.180-0.1.el8"
SLACK_URL="https://downloads.slack-edge.com/desktop-releases/linux/x64/${SLACK_VERSION}/slack-${SLACK_BUILD}.x86_64.rpm"

if ! rpm -q "slack-${SLACK_BUILD}.x86_64" >/dev/null 2>&1; then
else
fi

# --- Zoom ---
ZOOM_VERSION="7.1.5.4332"
ZOOM_URL="https://zoom.us/client/${ZOOM_VERSION}/zoom_x86_64.rpm"

if ! rpm -q "zoom-${ZOOM_VERSION}" >/dev/null 2>&1; then
else
fi

# --- Obsidian ---
OBSIDIAN_VERSION="1.13.4"
OBSIDIAN_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}.AppImage"
OBSIDIAN_APP="${DATA_DIR}/obsidian/${OBSIDIAN_VERSION}/app.AppImage"

if [ ! -f "$OBSIDIAN_APP" ]; then
else
fi
ln -fsT "$OBSIDIAN_APP" "$HOME/.local/bin/obsidian-app"

# --- Cursor ---
CURSOR_VERSION="3.15.6"
CURSOR_RPM_URL="https://downloads.cursor.com/production/a1f686545fd0ce8917bbd2449f733551a9bce420/linux/x64/rpm/x86_64/cursor-3.15.6.el8.x86_64.rpm"

if [ "$(rpm -q --qf '%{VERSION}' cursor 2>/dev/null || true)" != "$CURSOR_VERSION" ]; then
else
fi

# Cursor extensions
CURSOR_EXTENSIONS=(
)
if command -v cursor >/dev/null 2>&1; then
fi

# --- Zed ---
ZED_VERSION="1.14.2"
ZED_URL="https://github.com/zed-industries/zed/releases/download/v${ZED_VERSION}/zed-linux-x86_64.tar.gz"
ZED_DIR="${DATA_DIR}/zed/${ZED_VERSION}/zed.app"

if [ ! -d "$ZED_DIR" ]; then
else
fi
ln -fsT "${ZED_DIR}/bin/zed" "$HOME/.local/bin/zed"

# Desktop entry and icon
mkdir -p "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/512x512/apps"
sed "s|Icon=zed|Icon=${ZED_DIR}/share/icons/hicolor/512x512/apps/zed.png|; s|Exec=zed|Exec=${ZED_DIR}/bin/zed|" \
ln -fsT "${ZED_DIR}/share/icons/hicolor/512x512/apps/zed.png" \

# --- Yaak ---
YAAK_VERSION="2026.5.0"
YAAK_URL="https://github.com/mountain-loop/yaak/releases/download/v${YAAK_VERSION}/yaak-${YAAK_VERSION}-1.x86_64.rpm"

if ! rpm -q "yaak-${YAAK_VERSION}" >/dev/null 2>&1; then
else
fi

# --- SoapUI ---
SOAPUI_VERSION="5.10.0"
SOAPUI_URL="https://dl.eviware.com/soapuios/${SOAPUI_VERSION}/SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz"
SOAPUI_DIR="${DATA_DIR}/soap-ui/${SOAPUI_VERSION}/SoapUI-${SOAPUI_VERSION}"

if [ ! -d "$SOAPUI_DIR" ]; then
else
fi
ln -fsT "${SOAPUI_DIR}/bin/soapui.sh" "$HOME/.local/bin/soap-ui"
