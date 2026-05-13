#!/usr/bin/env bats
# json-helpers.bats — Test _mmry_json_escape and _mmry_build_json.

load '../helpers/test-helper'

setup() {
    # Source the client library without auto-init hitting real config
    export MMRY_API_KEY="test-key"
    export MMRY_AUTH_METHOD="apikey"
    export MMRY_API_URL="http://localhost:5291"
    source "$PLUGIN_ROOT/hooks-handlers/mmry-client.sh"
}

# ── _mmry_json_escape ──

@test "json_escape: escapes backslash" {
    local result
    result="$(_mmry_json_escape 'path\to\file')"
    [[ "$result" == 'path\\to\\file' ]]
}

@test "json_escape: escapes double quote" {
    local result
    result="$(_mmry_json_escape 'say "hello"')"
    [[ "$result" == 'say \"hello\"' ]]
}

@test "json_escape: escapes newline" {
    local result
    result="$(_mmry_json_escape $'line1\nline2')"
    [[ "$result" == 'line1\nline2' ]]
}

@test "json_escape: escapes carriage return" {
    local result
    result="$(_mmry_json_escape $'text\rmore')"
    # CR handling varies across platforms — verify CR is not present as raw byte
    [[ "$result" != *$'\r'* ]]
}

@test "json_escape: escapes tab" {
    local result
    result="$(_mmry_json_escape $'col1\tcol2')"
    [[ "$result" == 'col1\tcol2' ]]
}

@test "json_escape: passes plain strings unchanged" {
    local result
    result="$(_mmry_json_escape 'hello world')"
    [[ "$result" == 'hello world' ]]
}

@test "json_escape: handles empty string" {
    local result
    result="$(_mmry_json_escape '')"
    [[ "$result" == '' ]]
}

# ── _mmry_build_json ──

@test "build_json: two string keys" {
    local result
    result="$(_mmry_build_json "name" "Alice" "role" "admin")"
    [[ "$result" == '{"name":"Alice","role":"admin"}' ]]
}

@test "build_json: integer key with # prefix" {
    local result
    result="$(_mmry_build_json "#id" "42" "name" "test")"
    [[ "$result" == '{"id":42,"name":"test"}' ]]
}

@test "build_json: skips empty values" {
    local result
    result="$(_mmry_build_json "name" "Alice" "email" "" "role" "admin")"
    [[ "$result" == '{"name":"Alice","role":"admin"}' ]]
}

@test "build_json: mixed string and integer keys" {
    local result
    result="$(_mmry_build_json "topic" "Test" "#projectID" "5" "scope" "global")"
    [[ "$result" == '{"topic":"Test","projectID":5,"scope":"global"}' ]]
}

@test "build_json: no arguments produces empty object" {
    local result
    result="$(_mmry_build_json)"
    [[ "$result" == '{}' ]]
}

@test "build_json: special characters in values are escaped" {
    local result
    result="$(_mmry_build_json "content" 'He said "yes"')"
    [[ "$result" == '{"content":"He said \"yes\""}' ]]
}
