#!/usr/bin/env bats
# precompact-check.bats — Test precompact-check.sh debounce and output.

load '../helpers/test-helper'

@test "precompact-check: first invocation outputs block JSON and exits 2" {
    rm -f "$TEST_TMPDIR/.mnemo-precompact-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/precompact-check.sh"
    [[ "$status" -eq 2 ]]
    [[ "$output" == *'"decision":"block"'* ]]
}

@test "precompact-check: creates marker file" {
    rm -f "$TEST_TMPDIR/.mnemo-precompact-checked"
    bash "$PLUGIN_ROOT/hooks-handlers/precompact-check.sh" 2>/dev/null || true
    [[ -f "$TEST_TMPDIR/.mnemo-precompact-checked" ]]
}

@test "precompact-check: second invocation within 120s exits 0 and removes marker" {
    rm -f "$TEST_TMPDIR/.mnemo-precompact-checked"
    touch "$TEST_TMPDIR/.mnemo-precompact-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/precompact-check.sh"
    [[ "$status" -eq 0 ]]
    # Marker should be removed
    [[ ! -f "$TEST_TMPDIR/.mnemo-precompact-checked" ]]
}

@test "precompact-check: old marker (>120s) triggers block again" {
    touch -t 202001010000.00 "$TEST_TMPDIR/.mnemo-precompact-checked"
    run bash "$PLUGIN_ROOT/hooks-handlers/precompact-check.sh"
    [[ "$status" -eq 2 ]]
    [[ "$output" == *'"decision":"block"'* ]]
}
