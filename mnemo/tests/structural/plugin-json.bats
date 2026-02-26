#!/usr/bin/env bats
# plugin-json.bats — Validate plugin.json structure.

load '../helpers/test-helper'

PLUGIN_JSON=""

setup() {
    PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
}

@test "plugin.json exists" {
    [[ -f "$PLUGIN_JSON" ]]
}

@test "plugin.json is valid JSON" {
    if command -v jq &>/dev/null; then
        jq empty "$PLUGIN_JSON"
    else
        local content
        content="$(cat "$PLUGIN_JSON" | tr -d '[:space:]')"
        [[ "$content" == "{"* && "$content" == *"}" ]]
    fi
}

@test "plugin.json has name field = mnemo" {
    if command -v jq &>/dev/null; then
        local name
        name="$(jq -r '.name' "$PLUGIN_JSON")"
        [[ "$name" == "mnemo" ]]
    else
        grep -q '"name".*"mnemo"' "$PLUGIN_JSON"
    fi
}

@test "plugin.json has version field" {
    if command -v jq &>/dev/null; then
        local version
        version="$(jq -r '.version' "$PLUGIN_JSON")"
        [[ -n "$version" && "$version" != "null" ]]
    else
        grep -q '"version"' "$PLUGIN_JSON"
    fi
}

@test "plugin.json has description field" {
    if command -v jq &>/dev/null; then
        local desc
        desc="$(jq -r '.description' "$PLUGIN_JSON")"
        [[ -n "$desc" && "$desc" != "null" ]]
    else
        grep -q '"description"' "$PLUGIN_JSON"
    fi
}

@test "plugin.json has author field" {
    if command -v jq &>/dev/null; then
        local author
        author="$(jq -r '.author.name' "$PLUGIN_JSON")"
        [[ -n "$author" && "$author" != "null" ]]
    else
        grep -q '"author"' "$PLUGIN_JSON"
    fi
}
