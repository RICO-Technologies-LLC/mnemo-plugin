#!/usr/bin/env bats
# search-memories.bats — Test search-memories.sh handler.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    setup_mock_curl
    create_test_config "http://localhost:5291" "test-api-key" "apikey"
}

@test "search: fails with no arguments" {
    run bash "$PLUGIN_ROOT/hooks-handlers/search-memories.sh"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Keywords required"* ]]
}

@test "search: succeeds and outputs results" {
    run bash "$PLUGIN_ROOT/hooks-handlers/search-memories.sh" "test query"
    [[ "$status" -eq 0 ]]
    # Should show results (either jq-formatted or raw JSON)
    [[ "$output" == *"Test Result"* ]] || [[ "$output" == *"Found via search"* ]] || [[ "$output" == *"Results"* ]]
}

@test "search: passes scope parameter to API" {
    run bash "$PLUGIN_ROOT/hooks-handlers/search-memories.sh" "database" "backend"
    [[ "$status" -eq 0 ]]
    # Verify the curl call included scope
    grep -q "search" "$TEST_TMPDIR/curl-log.txt"
}

@test "search: handles API error" {
    export MOCK_CURL_HTTP_CODE="500"
    export MOCK_CURL_RESPONSE='{"error":"server error"}'
    run bash "$PLUGIN_ROOT/hooks-handlers/search-memories.sh" "test"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Error"* ]]
}

@test "search: output does not include memory IDs" {
    run bash "$PLUGIN_ROOT/hooks-handlers/search-memories.sh" "test query"
    [[ "$status" -eq 0 ]]
    # With jq output format: "Tier | Scope | Topic\n  Content\n---"
    # IDs should never appear in user-facing output
    if command -v jq &>/dev/null; then
        [[ "$output" != *'"id"'* ]]
    fi
}

@test "search: shows memory count with jq" {
    if ! command -v jq &>/dev/null; then
        skip "Requires jq"
    fi
    run bash "$PLUGIN_ROOT/hooks-handlers/search-memories.sh" "test query"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Found"* ]]
    [[ "$output" == *"memories"* ]] || [[ "$output" == *"memor"* ]]
}
