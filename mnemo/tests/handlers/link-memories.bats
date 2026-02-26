#!/usr/bin/env bats
# link-memories.bats — Test link-memories.sh handler.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    setup_mock_curl
    create_test_config "http://localhost:5291" "test-api-key" "apikey"
}

@test "link: fails with missing arguments" {
    run bash "$PLUGIN_ROOT/hooks-handlers/link-memories.sh"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"Error"* ]]
}

@test "link: fails with only one argument" {
    run bash "$PLUGIN_ROOT/hooks-handlers/link-memories.sh" 1
    [[ "$status" -ne 0 ]]
}

@test "link: fails with only two arguments" {
    run bash "$PLUGIN_ROOT/hooks-handlers/link-memories.sh" 1 2
    [[ "$status" -ne 0 ]]
}

@test "link: succeeds with all three arguments" {
    run bash "$PLUGIN_ROOT/hooks-handlers/link-memories.sh" 42 87 "related"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memories linked."* ]]
}

@test "link: handles API error" {
    export MOCK_CURL_HTTP_CODE="400"
    export MOCK_CURL_RESPONSE='{"error":"Invalid link type"}'
    run bash "$PLUGIN_ROOT/hooks-handlers/link-memories.sh" 1 2 "invalid"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Error"* ]]
}

@test "link: does not output memory IDs" {
    run bash "$PLUGIN_ROOT/hooks-handlers/link-memories.sh" 42 87 "related"
    [[ "$status" -eq 0 ]]
    [[ "$output" != *"42"* ]]
    [[ "$output" != *"87"* ]]
}
