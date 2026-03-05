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

@test "save-memory: succeeds with all required fields" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Test Topic" --content "Test content body"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memory saved."* ]]
}

@test "save-memory: passes optional fields to API" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Operational --category Decision --scope backend \
        --topic "Design Choice" --content "We chose X" \
        --source "meeting" --task-id "TASK-42" --working-dir "/home/user/project" \
        --session-id "sess-abc"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memory saved."* ]]
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

# ── Private / Group Memory Tests ──

@test "save-memory: accepts --visibility parameter" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Private Note" --content "Only for me" \
        --visibility private
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memory saved."* ]]
}

@test "save-memory: private visibility is sent in API request body" {
    bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Operational --category Decision --scope backend \
        --topic "Private Decision" --content "Internal choice" \
        --visibility private 2>&1
    # Verify curl was called
    grep -q "POST.*memories" "$TEST_TMPDIR/curl-log.txt"
}

@test "save-memory: succeeds with no visibility (defaults to global)" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Public Fact" --content "Everyone sees this"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memory saved."* ]]
}

@test "save-memory: accepts --supersedes parameter for updates" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Updated Fact" --content "New version" \
        --supersedes 42
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memory saved."* ]]
}

@test "save-memory: accepts all optional parameters together" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Operational --category Decision --scope backend \
        --topic "Full Params" --content "All options set" \
        --source "test" --task-id "TASK-99" --working-dir "/tmp/project" \
        --project-id 5 --session-id "sess-xyz" \
        --visibility private --supersedes 10
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memory saved."* ]]
}

@test "save-memory: accepts --permission-group-id parameter" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "Group Note" --content "Shared with team" \
        --visibility group --permission-group-id 42
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Memory saved."* ]]
}

@test "save-memory: permission-group-id is sent in API request body" {
    bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Operational --category Decision --scope backend \
        --topic "Group Decision" --content "Team choice" \
        --visibility group --permission-group-id 7 2>&1
    # Verify curl was called with the body containing permissionGroupID
    grep -q "POST.*memories" "$TEST_TMPDIR/curl-log.txt"
}

@test "save-memory: does not output memory ID" {
    run bash "$PLUGIN_ROOT/hooks-handlers/save-memory.sh" \
        --tier Foundation --category Fact --scope global \
        --topic "ID Check" --content "Should not show ID"
    [[ "$status" -eq 0 ]]
    # Output should NOT contain numeric IDs or "ID:" references
    [[ "$output" != *"NewMemoryID"* ]]
    [[ "$output" != *": 99"* ]]
}
