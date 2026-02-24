#!/usr/bin/env bash
# uninstall.sh — Uninstall Mnemo plugin for Claude Code (macOS/Linux)
set -euo pipefail

SETTINGS_PATH="${HOME}/.claude/settings.json"
MARKETPLACE_NAME="internal-plugins"
PLUGIN_NAME="mnemo@internal-plugins"

if [[ ! -f "$SETTINGS_PATH" ]]; then
    echo "Nothing to uninstall."
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required for uninstallation."
    exit 1
fi

settings="$(cat "$SETTINGS_PATH")"

# Remove plugin and marketplace using jq
settings="$(echo "$settings" | jq --arg name "$PLUGIN_NAME" '
    if .enabledPlugins then del(.enabledPlugins[$name]) else . end |
    if .enabledPlugins and (.enabledPlugins | length) == 0 then del(.enabledPlugins) else . end
')"

settings="$(echo "$settings" | jq --arg name "$MARKETPLACE_NAME" '
    if .extraKnownMarketplaces then del(.extraKnownMarketplaces[$name]) else . end |
    if .extraKnownMarketplaces and (.extraKnownMarketplaces | length) == 0 then del(.extraKnownMarketplaces) else . end
')"

echo "$settings" | jq '.' > "$SETTINGS_PATH"

echo "Mnemo memory plugin uninstalled!"
echo ""
echo "Restart Claude Code to take effect."
