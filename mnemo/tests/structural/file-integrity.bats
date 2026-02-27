#!/usr/bin/env bats
# file-integrity.bats — Verify all expected plugin files exist and are well-formed.

load '../helpers/test-helper'

# ── hooks-handlers/ scripts ──

@test "hooks-handlers/mnemo-client.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh" ]]
}

@test "hooks-handlers/session-start.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/session-start.sh" ]]
}

@test "hooks-handlers/session-init.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/session-init.sh" ]]
}

@test "hooks-handlers/hook-guard.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/hook-guard.sh" ]]
}

@test "hooks-handlers/save-memory.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" ]]
}

@test "hooks-handlers/reinforce-memory.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/reinforce-memory.sh" ]]
}

@test "hooks-handlers/deactivate-memory.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/deactivate-memory.sh" ]]
}

@test "hooks-handlers/link-memories.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/link-memories.sh" ]]
}

@test "hooks-handlers/search-memories.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/search-memories.sh" ]]
}

@test "hooks-handlers/stop-check.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/stop-check.sh" ]]
}

@test "hooks-handlers/precompact-check.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/precompact-check.sh" ]]
}

@test "hooks-handlers/plan-accepted-check.sh exists" {
    [[ -f "$PLUGIN_ROOT/hooks-handlers/plan-accepted-check.sh" ]]
}

# ── shebangs ──

@test "all .sh files in hooks-handlers/ have bash shebang" {
    local failures=""
    for f in "$PLUGIN_ROOT"/hooks-handlers/*.sh; do
        local first_line
        first_line="$(head -1 "$f")"
        if [[ "$first_line" != "#!/usr/bin/env bash" && "$first_line" != "#!/bin/bash" ]]; then
            failures+="  $(basename "$f"): $first_line\n"
        fi
    done
    if [[ -n "$failures" ]]; then
        fail "Missing bash shebang:\n$failures"
    fi
}

@test "all multi-line .sh files in hooks-handlers/ have set -euo pipefail" {
    local failures=""
    for f in "$PLUGIN_ROOT"/hooks-handlers/*.sh; do
        # Skip tiny scripts (< 5 lines) like plan-accepted-check.sh
        local lines
        lines="$(wc -l < "$f" | tr -d ' ')"
        (( lines < 6 )) && continue
        if ! grep -q 'set -euo pipefail' "$f"; then
            failures+="  $(basename "$f")\n"
        fi
    done
    if [[ -n "$failures" ]]; then
        fail "Missing 'set -euo pipefail':\n$failures"
    fi
}

# ── setup/ scripts ──

@test "setup/mnemo-setup.sh exists" {
    [[ -f "$PLUGIN_ROOT/setup/mnemo-setup.sh" ]]
}

@test "setup/mnemo-setup.bat exists" {
    [[ -f "$PLUGIN_ROOT/setup/mnemo-setup.bat" ]]
}

@test "setup/install.sh exists" {
    [[ -f "$PLUGIN_ROOT/setup/install.sh" ]]
}

@test "setup/uninstall.sh exists" {
    [[ -f "$PLUGIN_ROOT/setup/uninstall.sh" ]]
}

# ── config example ──

@test "mnemo-config.example.json is valid JSON" {
    local file="$PLUGIN_ROOT/mnemo-config.example.json"
    if command -v jq &>/dev/null; then
        jq empty "$file"
    else
        # Minimal check: starts with { and ends with }
        local content
        content="$(cat "$file" | tr -d '[:space:]')"
        [[ "$content" == "{"* && "$content" == *"}" ]]
    fi
}

# ── skill doc ──

@test "skills/memory-system/SKILL.md exists and is non-empty" {
    [[ -s "$PLUGIN_ROOT/skills/memory-system/SKILL.md" ]]
}
