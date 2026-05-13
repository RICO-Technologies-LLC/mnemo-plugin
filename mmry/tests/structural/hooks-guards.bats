#!/usr/bin/env bats
# hooks-guards.bats — Verify hooks.json guards and error message correctness.

load '../helpers/test-helper'

# ── hooks.json uses hook-guard.sh for guarded hooks ──

@test "Stop hook delegates to hook-guard.sh" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    local stop_cmd
    stop_cmd="$(grep -A5 '"Stop"' "$hooks_file" | grep '"command"')"
    [[ "$stop_cmd" == *'hook-guard.sh'* ]]
    [[ "$stop_cmd" == *'stop-check'* ]]
}

@test "PreCompact hook delegates to hook-guard.sh" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    local precompact_cmd
    precompact_cmd="$(grep -A5 '"PreCompact"' "$hooks_file" | grep '"command"')"
    [[ "$precompact_cmd" == *'hook-guard.sh'* ]]
    [[ "$precompact_cmd" == *'precompact-check'* ]]
}

@test "PostToolUse hook delegates to hook-guard.sh" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    local posttool_cmd
    posttool_cmd="$(grep -A10 '"PostToolUse"' "$hooks_file" | grep '"command"')"
    [[ "$posttool_cmd" == *'hook-guard.sh'* ]]
    [[ "$posttool_cmd" == *'plan-accepted-check'* ]]
}

@test "SessionStart hook delegates to session-init.sh" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    local session_cmd
    session_cmd="$(grep -A10 '"SessionStart"' "$hooks_file" | grep '"command"')"
    [[ "$session_cmd" == *'session-init.sh'* ]]
}

# ── hooks.json has no bash -c (Windows quoting fix) ──

@test "hooks.json guard hooks use bash -c with existence check" {
    local hooks_file="$PLUGIN_ROOT/hooks/hooks.json"
    # Guard-based hooks (Stop, PreCompact, PostToolUse) intentionally use bash -c
    # to check if the stable copy exists before running
    local guard_cmds
    guard_cmds="$(grep '"command"' "$hooks_file" | grep 'hook-guard.sh')"
    [[ -n "$guard_cmds" ]]
    echo "$guard_cmds" | while IFS= read -r line; do
        [[ "$line" == *'bash -c'* ]]
        [[ "$line" == *'[ -f'* ]]
        [[ "$line" == *'|| true'* ]]
    done
}

# ── hook-guard.sh behavior ──

@test "hook-guard.sh exits 0 silently when target script does not exist" {
    run bash "$PLUGIN_ROOT/hooks-handlers/hook-guard.sh" nonexistent-script
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

@test "hook-guard.sh exits 0 silently when no argument given" {
    run bash "$PLUGIN_ROOT/hooks-handlers/hook-guard.sh"
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
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
