#!/usr/bin/env bats
# deactivate-memory.bats — Test deactivate-memory.sh handler.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    setup_mock_curl
    create_test_config "http://localhost:5291" "test-api-key" "apikey"
}

@test "deactivate: fails with no arguments" {
    run bash "$PLUGIN_ROOT/hooks-handlers/deactivate-memory.sh"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Memory ID required"* ]]
}

@test "deactivate: succeeds with valid ID" {
    run bash "$PLUGIN_ROOT/hooks-handlers/deactivate-memory.sh" 42
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Deactivated memory ID: 42"* ]]
}

@test "deactivate: handles API error" {
    export MOCK_CURL_HTTP_CODE="404"
    export MOCK_CURL_RESPONSE='{"error":"Memory not found"}'
    run bash "$PLUGIN_ROOT/hooks-handlers/deactivate-memory.sh" 999
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Error"* ]]
}
