#!/usr/bin/env bash
# uninstall.sh — Uninstall Mnemo plugin for Claude Code (macOS/Linux)
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SETTINGS_PATH="${CLAUDE_DIR}/settings.json"
CONFIG_PATH="${CLAUDE_DIR}/mnemo-config.json"

# Handle both marketplace and local install key names
PLUGIN_NAMES=("mnemo@mnemo-plugin" "mnemo@internal-plugins")
MARKETPLACE_NAMES=("mnemo-plugin" "internal-plugins")
MNEMO_PERMISSIONS=(
    "Bash(*save-memory.sh*)"
    "Bash(*reinforce-memory.sh*)"
    "Bash(*deactivate-memory.sh*)"
    "Bash(*link-memories.sh*)"
    "Bash(*search-memories.sh*)"
    "Bash(*mnemo-client.sh*)"
)

echo ""
echo "=== Mnemo Uninstall ==="
echo ""

# Step 1: Remove config file
if [[ -f "$CONFIG_PATH" ]]; then
    rm -f "$CONFIG_PATH"
    echo "  Removed mnemo-config.json"
else
    echo "  No config file found (already removed)."
fi

# Step 2: Clean settings.json (plugin, marketplace, permissions)
if [[ ! -f "$SETTINGS_PATH" ]]; then
    echo "  No settings.json found."
else
    HAS_JQ=false
    if command -v jq &>/dev/null; then
        HAS_JQ=true
    fi

    if $HAS_JQ; then
        settings="$(cat "$SETTINGS_PATH")"

        # Remove plugin entries
        for name in "${PLUGIN_NAMES[@]}"; do
            settings="$(echo "$settings" | jq --arg name "$name" '
                if .enabledPlugins then del(.enabledPlugins[$name]) else . end
            ')"
        done
        settings="$(echo "$settings" | jq '
            if .enabledPlugins and (.enabledPlugins | length) == 0 then del(.enabledPlugins) else . end
        ')"

        # Remove marketplace entries
        for name in "${MARKETPLACE_NAMES[@]}"; do
            settings="$(echo "$settings" | jq --arg name "$name" '
                if .extraKnownMarketplaces then del(.extraKnownMarketplaces[$name]) else . end
            ')"
        done
        settings="$(echo "$settings" | jq '
            if .extraKnownMarketplaces and (.extraKnownMarketplaces | length) == 0 then del(.extraKnownMarketplaces) else . end
        ')"

        # Remove Mnemo permissions
        for perm in "${MNEMO_PERMISSIONS[@]}"; do
            settings="$(echo "$settings" | jq --arg p "$perm" '
                if .permissions.allow then .permissions.allow -= [$p] else . end
            ')"
        done
        settings="$(echo "$settings" | jq '
            if .permissions.allow and (.permissions.allow | length) == 0 then del(.permissions.allow) else . end |
            if .permissions and (.permissions | length) == 0 then del(.permissions) else . end
        ')"

        echo "$settings" | jq '.' > "$SETTINGS_PATH"
        echo "  Cleaned settings.json (plugin, marketplace, permissions)"
    else
        # Try Python fallback
        PY_CMD=""
        if command -v python3 &>/dev/null; then
            PY_CMD="python3"
        elif command -v python &>/dev/null; then
            PY_CMD="python"
        fi

        if [[ -n "$PY_CMD" ]]; then
            "$PY_CMD" - "$SETTINGS_PATH" << 'PYEOF'
import json, sys
sf = sys.argv[1]
plugin_names = ["mnemo@mnemo-plugin", "mnemo@internal-plugins"]
marketplace_names = ["mnemo-plugin", "internal-plugins"]
mnemo_perms = [
    "Bash(*save-memory.sh*)",
    "Bash(*reinforce-memory.sh*)",
    "Bash(*deactivate-memory.sh*)",
    "Bash(*link-memories.sh*)",
    "Bash(*search-memories.sh*)",
    "Bash(*mnemo-client.sh*)"
]
with open(sf) as f:
    data = json.load(f)
if "enabledPlugins" in data:
    for name in plugin_names:
        data["enabledPlugins"].pop(name, None)
    if not data["enabledPlugins"]:
        del data["enabledPlugins"]
if "extraKnownMarketplaces" in data:
    for name in marketplace_names:
        data["extraKnownMarketplaces"].pop(name, None)
    if not data["extraKnownMarketplaces"]:
        del data["extraKnownMarketplaces"]
if "permissions" in data and "allow" in data["permissions"]:
    data["permissions"]["allow"] = [p for p in data["permissions"]["allow"] if p not in mnemo_perms]
    if not data["permissions"]["allow"]:
        del data["permissions"]["allow"]
    if not data["permissions"]:
        del data["permissions"]
with open(sf, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
            echo "  Cleaned settings.json (plugin, marketplace, permissions)"
        else
            echo "  Warning: jq and python not found. Manually edit ${SETTINGS_PATH}:"
            echo "    - Remove mnemo entries from enabledPlugins"
            echo "    - Remove mnemo entries from extraKnownMarketplaces"
            echo "    - Remove Mnemo permissions from permissions.allow"
        fi
    fi
fi

# Step 3: Remove stable hooks directory
if [[ -d "${HOME}/.claude/mnemo" ]]; then
    rm -rf "${HOME}/.claude/mnemo"
    echo "  Removed ~/.claude/mnemo/"
fi

# Step 4: Clear plugin cache
for cache_name in "mnemo-plugin" "internal-plugins"; do
    CACHE_DIR="${CLAUDE_DIR}/plugins/cache/${cache_name}/mnemo"
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        echo "  Cleared plugin cache (${cache_name})"
    fi
done

echo ""
echo "Mnemo uninstalled."
echo "Restart Claude Code to take effect."
echo ""
