#!/usr/bin/env bats
# hooks-guards.bats — Verify hooks.json guards and error message correctness.

load '../helpers/test-helper'

# ── hooks.json file-existence guards ──

@test "Stop hook contains file-existence guard" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    local stop_cmd
    stop_cmd="$(grep -A5 '"Stop"' "$hooks_file" | grep '"command"')"
    [[ "$stop_cmd" == *'[ -f '* ]]
}

@test "PreCompact hook contains file-existence guard" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    local precompact_cmd
    precompact_cmd="$(grep -A5 '"PreCompact"' "$hooks_file" | grep '"command"')"
    [[ "$precompact_cmd" == *'[ -f '* ]]
}

@test "PostToolUse hook contains file-existence guard" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    local posttool_cmd
    posttool_cmd="$(grep -A10 '"PostToolUse"' "$hooks_file" | grep '"command"')"
    [[ "$posttool_cmd" == *'[ -f '* ]]
}

# ── SessionStart error visibility ──

@test "SessionStart hook does not suppress cp errors with 2>/dev/null" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    # Extract the SessionStart command line
    local session_cmd
    session_cmd="$(grep -A10 '"SessionStart"' "$hooks_file" | grep '"command"')"
    # The cp commands should not have 2>/dev/null
    # Split on cp to check each cp invocation
    local cp_fragments
    cp_fragments="$(echo "$session_cmd" | grep -o 'cp [^;]*')"
    while IFS= read -r fragment; do
        if [[ "$fragment" == *'2>/dev/null'* ]]; then
            fail "SessionStart cp command suppresses errors: $fragment"
        fi
    done <<< "$cp_fragments"
}

# ── mnemo-client.sh error message ──

@test "mnemo-client.sh no-API-key message references /mnemo:setup" {
    local client_file="$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
    grep -q '/mnemo:setup' "$client_file"
}

@test "mnemo-client.sh no-API-key message does not reference file path" {
    local client_file="$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
    # The old message contained a file path to mnemo-setup.sh
    ! grep -q 'mnemo-setup\.sh' "$client_file"
}
