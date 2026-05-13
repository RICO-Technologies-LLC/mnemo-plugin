#!/usr/bin/env bats
# marketplace-sync.bats — Assert plugin.json version matches marketplace.json version.
#
# Why this exists:
# The plugin has two version fields in the repo. mmry/.claude-plugin/plugin.json is
# the plugin's own identifier (bumped per feature PR). .claude-plugin/marketplace.json
# is the marketplace's declaration of the latest version. self-update.sh compares the
# LOCAL plugin's plugin.json version against the REMOTE marketplace.json version.
#
# When these drift, every installed plugin sees "old == old" against the stale marketplace
# entry and silently skips auto-update. v1.8 shipped feature work that never reached users
# because marketplace.json was left behind at 1.2.8 while plugin.json moved to 1.2.11.
# This test ensures the two stay in lock-step.

load '../helpers/test-helper'

PLUGIN_JSON=""
MARKETPLACE_JSON=""

setup() {
    PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
    MARKETPLACE_JSON="$PLUGIN_ROOT/../.claude-plugin/marketplace.json"
}

@test "marketplace.json exists at repo root .claude-plugin/" {
    [[ -f "$MARKETPLACE_JSON" ]]
}

@test "marketplace.json is valid JSON" {
    if command -v jq &>/dev/null; then
        jq empty "$MARKETPLACE_JSON"
    else
        local content
        content="$(cat "$MARKETPLACE_JSON" | tr -d '[:space:]')"
        [[ "$content" == "{"* && "$content" == *"}" ]]
    fi
}

@test "marketplace.json has a mmry plugin entry with a version field" {
    if command -v jq &>/dev/null; then
        local version
        version="$(jq -r '.plugins[] | select(.name == "mmry") | .version' "$MARKETPLACE_JSON")"
        [[ -n "$version" && "$version" != "null" ]]
    else
        # Fallback: look for the version key anywhere; precision lost but better than nothing.
        grep -q '"version"' "$MARKETPLACE_JSON"
    fi
}

@test "plugin.json version equals marketplace.json mmry plugin version" {
    local plugin_ver market_ver

    if command -v jq &>/dev/null; then
        plugin_ver="$(jq -r '.version' "$PLUGIN_JSON")"
        market_ver="$(jq -r '.plugins[] | select(.name == "mmry") | .version' "$MARKETPLACE_JSON")"
    else
        # Fallback parse: take first "version": "X" occurrence in each file.
        plugin_ver="$(grep -o '"version"[^"]*"[^"]*"' "$PLUGIN_JSON" | head -1 | grep -o '"[0-9][^"]*"' | tr -d '"')"
        market_ver="$(grep -o '"version"[^"]*"[^"]*"' "$MARKETPLACE_JSON" | head -1 | grep -o '"[0-9][^"]*"' | tr -d '"')"
    fi

    [[ -n "$plugin_ver" && "$plugin_ver" != "null" ]] || \
        { echo "plugin.json version not found"; return 1; }
    [[ -n "$market_ver" && "$market_ver" != "null" ]] || \
        { echo "marketplace.json mmry version not found"; return 1; }

    if [[ "$plugin_ver" != "$market_ver" ]]; then
        echo "VERSION MISMATCH:"
        echo "  plugin.json      = $plugin_ver"
        echo "  marketplace.json = $market_ver"
        echo ""
        echo "Both files must be bumped together. See plugin/guide.md release checklist."
        return 1
    fi
}
