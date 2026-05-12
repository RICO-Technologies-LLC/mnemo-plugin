#!/usr/bin/env bats
# stop-check.bats — Test stop-check.sh debounce and output.

load '../helpers/test-helper'

@test "stop-check: first invocation outputs block JSON and exits 2" {
    # Ensure no marker exists
    rm -f "$TEST_TMPDIR/.mnemo-stop-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh"
    [[ "$status" -eq 2 ]]
    [[ "$output" == *'"decision":"block"'* ]]
}

@test "stop-check: creates marker file" {
    rm -f "$TEST_TMPDIR/.mnemo-stop-checked"
    bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh" 2>/dev/null || true
    [[ -f "$TEST_TMPDIR/.mnemo-stop-checked" ]]
}

@test "stop-check: second invocation within 120s exits 0 (debounce)" {
    # Create fresh marker
    rm -f "$TEST_TMPDIR/.mnemo-stop-checked"
    touch "$TEST_TMPDIR/.mnemo-stop-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh"
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

@test "stop-check: old marker (>120s) triggers block again" {
    # Create marker with old timestamp
    touch -t 202001010000.00 "$TEST_TMPDIR/.mnemo-stop-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh"
    [[ "$status" -eq 2 ]]
    [[ "$output" == *'"decision":"block"'* ]]
}

# --- Directive-wording contract (#29854) --------------------------------------

@test "stop-check: reason field reads as a directive, not a status line" {
    rm -f "$TEST_TMPDIR/.mnemo-stop-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh"
    [[ "$status" -eq 2 ]]
    # Reason must start with BLOCKED: (or carry equivalent directive marker).
    [[ "$output" == *'"reason":"BLOCKED:'* ]]
    # Must not contain the old ambiguous status-line phrasing.
    [[ "$output" != *'"reason":"Mnemo: saving important memories'* ]]
}

@test "stop-check: systemMessage includes the full process-context.sh command" {
    rm -f "$TEST_TMPDIR/.mnemo-stop-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh"
    [[ "$status" -eq 2 ]]
    [[ "$output" == *'process-context.sh'* ]]
    # All four required flags must be visible.
    [[ "$output" == *'--hook-type'* ]]
    [[ "$output" == *'--context'* ]]
    [[ "$output" == *'--working-dir'* ]]
    [[ "$output" == *'--session-id'* ]]
}

@test "stop-check: systemMessage instructs run-in-background" {
    rm -f "$TEST_TMPDIR/.mnemo-stop-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh"
    [[ "$status" -eq 2 ]]
    [[ "$output" == *'run_in_background'* ]] || [[ "$output" == *'IN THE BACKGROUND'* ]]
}

@test "stop-check: systemMessage forbids Acknowledged-style responses" {
    rm -f "$TEST_TMPDIR/.mnemo-stop-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/stop-check.sh"
    [[ "$status" -eq 2 ]]
    # The directive must explicitly call out the failure mode it exists to prevent.
    [[ "$output" == *'Acknowledged'* ]]
    [[ "$output" == *'Do NOT'* ]] || [[ "$output" == *'do not'* ]]
}
