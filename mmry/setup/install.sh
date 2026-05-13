#!/usr/bin/env bash
# install.sh — Install Mnemo plugin for Claude Code (macOS/Linux)
set -euo pipefail

SETTINGS_PATH="${HOME}/.claude/settings.json"
MARKETPLACE_NAME="internal-plugins"
PLUGIN_NAME="mnemo@internal-plugins"
MARKETPLACE_PATH="$(cd "$(dirname "$0")/../.." && pwd)"

# Ensure .claude directory exists
mkdir -p "${HOME}/.claude"

# Check for jq
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required for installation. Install it first:"
    echo "  macOS: brew install jq"
    echo "  Linux: sudo apt-get install jq"
    exit 1
fi

# Warn if bash version is below 4 (macOS ships bash 3.2)
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "Warning: bash ${BASH_VERSION} detected. Bash 4+ is recommended."
    echo "  macOS: brew install bash"
fi

# Load or create settings
if [[ -f "$SETTINGS_PATH" ]]; then
    settings="$(cat "$SETTINGS_PATH")"
else
    settings='{}'
fi

# Add marketplace and enable plugin using jq
settings="$(echo "$settings" | jq --arg name "$MARKETPLACE_NAME" --arg path "$MARKETPLACE_PATH" '
    .extraKnownMarketplaces //= {} |
    .extraKnownMarketplaces[$name] //= {"source": {"source": "directory", "path": $path}}
')"

settings="$(echo "$settings" | jq --arg name "$PLUGIN_NAME" '
    .enabledPlugins //= {} |
    .enabledPlugins[$name] //= true
')"

# Disable built-in auto memory (Mnemo replaces it)
settings="$(echo "$settings" | jq '.autoMemoryEnabled = false')"

echo "$settings" | jq '.' > "$SETTINGS_PATH"

echo "Mnemo memory plugin installed!"
echo ""
echo "Restart Claude Code to activate."
