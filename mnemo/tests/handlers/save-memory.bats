#!/usr/bin/env bats
# save-memory.bats — Test save-memory.sh handler.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    setup_mock_curl
    create_test_config "http://localhost:5291" "test-api-key" "apikey"
}

@test "save-memory: fails with missing --tier" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --category Fact --scope global --topic "Test" --content "Content"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"--tier"* ]]
}

@test "save-memory: fails with missing --category" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --scope global --topic "Test" --content "Content"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"--category"* ]]
}

@test "save-memory: fails with missing --scope" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --topic "Test" --content "Content"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"--scope"* ]]
}

@test "save-memory: fails with missing --topic" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global --content "Content"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"--topic"* ]]
}

@test "save-memory: fails with missing --content" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global --topic "Test"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"--content"* ]]
}

@test "save-memory: succeeds with all required fields, outputs NewMemoryID" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Test Topic" --content "Test content body"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"NewMemoryID:"* ]]
    [[ "$output" == *"99"* ]]
}

@test "save-memory: passes optional fields to API" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Operational --category Decision --scope backend \
        --topic "Design Choice" --content "We chose X" \
        --source "meeting" --task-id "TASK-42" --working-dir "/home/user/project" \
        --session-id "sess-abc"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"NewMemoryID:"* ]]
    # Verify curl was called with the body
    grep -q "POST.*memories" "$TEST_TMPDIR/curl-log.txt"
}

@test "save-memory: handles API error" {
    export MOCK_CURL_HTTP_CODE="400"
    export MOCK_CURL_RESPONSE='{"error":"Validation failed"}'
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Test" --content "Content"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Error"* ]]
}

@test "save-memory: fails on unknown argument" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Test" --content "Content" --unknown-flag value
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Unknown argument"* ]]
}
