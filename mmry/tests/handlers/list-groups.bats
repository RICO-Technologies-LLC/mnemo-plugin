#!/usr/bin/env bats
# list-groups.bats — Test list-groups.sh handler.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    setup_mock_curl
    create_test_config "http://localhost:5291" "test-api-key" "apikey"
}

@test "list-groups: succeeds and outputs groups" {
    run bash "$PLUGIN_ROOT/hooks-handlers/list-groups.sh"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Finance Team"* ]] || [[ "$output" == *"groups"* ]]
}

@test "list-groups: shows group count with jq" {
    if ! command -v jq &>/dev/null; then
        skip "Requires jq"
    fi
    run bash "$PLUGIN_ROOT/hooks-handlers/list-groups.sh"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"2 group"* ]]
}

@test "list-groups: shows group IDs and names with jq" {
    if ! command -v jq &>/dev/null; then
        skip "Requires jq"
    fi
    run bash "$PLUGIN_ROOT/hooks-handlers/list-groups.sh"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"ID: 1"* ]]
    [[ "$output" == *"Finance Team"* ]]
    [[ "$output" == *"ID: 2"* ]]
    [[ "$output" == *"Engineering"* ]]
}

@test "list-groups: handles empty group list" {
    export MOCK_CURL_RESPONSE='[]'
    run bash "$PLUGIN_ROOT/hooks-handlers/list-groups.sh"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"No groups"* ]] || [[ "$output" == *"[]"* ]]
}

@test "list-groups: handles API error" {
    export MOCK_CURL_HTTP_CODE="500"
    export MOCK_CURL_RESPONSE='{"error":"server error"}'
    run bash "$PLUGIN_ROOT/hooks-handlers/list-groups.sh"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Error"* ]]
}

@test "list-groups: calls correct API endpoint" {
    bash "$PLUGIN_ROOT/hooks-handlers/list-groups.sh" 2>&1
    grep -q "GET.*groups/mine" "$TEST_TMPDIR/curl-log.txt"
}
