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
