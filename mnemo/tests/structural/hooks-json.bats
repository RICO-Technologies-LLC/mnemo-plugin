#!/usr/bin/env bats
# hooks-json.bats — Validate hooks.json structure and references.

load '../helpers/test-helper'

HOOKS_FILE=""

setup() {
    HOOKS_FILE="$PLUGIN_ROOT/hooks/hooks.json"
}

@test "hooks.json exists" {
    [[ -f "$HOOKS_FILE" ]]
}

@test "hooks.json is valid JSON" {
    if command -v jq &>/dev/null; then
        jq empty "$HOOKS_FILE"
    else
        local content
        content="$(cat "$HOOKS_FILE" | tr -d '[:space:]')"
        [[ "$content" == "{"* && "$content" == *"}" ]]
    fi
}

@test "hooks.json has SessionStart hook" {
    if command -v jq &>/dev/null; then
        local count
        count="$(jq '.hooks.SessionStart | length' "$HOOKS_FILE")"
        (( count >= 1 ))
    else
        grep -q '"SessionStart"' "$HOOKS_FILE"
    fi
}

@test "hooks.json has Stop hook" {
    if command -v jq &>/dev/null; then
        local count
        count="$(jq '.hooks.Stop | length' "$HOOKS_FILE")"
        (( count >= 1 ))
    else
        grep -q '"Stop"' "$HOOKS_FILE"
    fi
}

@test "hooks.json has PreCompact hook" {
    if command -v jq &>/dev/null; then
        local count
        count="$(jq '.hooks.PreCompact | length' "$HOOKS_FILE")"
        (( count >= 1 ))
    else
        grep -q '"PreCompact"' "$HOOKS_FILE"
    fi
}

@test "hooks.json has PostToolUse hook with ExitPlanMode matcher" {
    if command -v jq &>/dev/null; then
        local matcher
        matcher="$(jq -r '.hooks.PostToolUse[0].matcher' "$HOOKS_FILE")"
        [[ "$matcher" == "ExitPlanMode" ]]
    else
        grep -q '"ExitPlanMode"' "$HOOKS_FILE"
    fi
}

@test "hooks.json command paths reference session-start.sh" {
    grep -q 'session-start.sh' "$HOOKS_FILE"
}

@test "hooks.json command paths reference stop-check.sh" {
    grep -q 'stop-check.sh' "$HOOKS_FILE"
}

@test "hooks.json command paths reference precompact-check.sh" {
    grep -q 'precompact-check.sh' "$HOOKS_FILE"
}

@test "hooks.json command paths reference plan-accepted-check.sh" {
    grep -q 'plan-accepted-check.sh' "$HOOKS_FILE"
}
