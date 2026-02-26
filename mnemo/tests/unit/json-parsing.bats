#!/usr/bin/env bats
# json-parsing.bats — Test _mnemo_parse_json_value.

load '../helpers/test-helper'

setup() {
    export MNEMO_API_KEY="test-key"
    export MNEMO_AUTH_METHOD="apikey"
    export MNEMO_API_URL="http://localhost:5291"
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
}

@test "parse_json_value: extracts string value from simple JSON" {
    local json='{"name":"Alice","role":"admin"}'
    local result
    result="$(_mnemo_parse_json_value "$json" "name")"
    [[ "$result" == "Alice" ]]
}

@test "parse_json_value: returns empty for missing key" {
    local json='{"name":"Alice"}'
    local result
    result="$(_mnemo_parse_json_value "$json" "email")"
    [[ "$result" == "" ]]
}

@test "parse_json_value: extracts first value when key appears multiple times" {
    local json='{"name":"Alice","items":[{"name":"first"}]}'
    local result
    result="$(_mnemo_parse_json_value "$json" "name")"
    [[ "$result" == "Alice" ]]
}

@test "parse_json_value: works with spaces around colons" {
    local json='{"name" : "Bob"}'
    local result
    result="$(_mnemo_parse_json_value "$json" "name")"
    [[ "$result" == "Bob" ]]
}

@test "parse_json_value: extracts URL value" {
    local json='{"apiUrl":"https://example.com","apiKey":"abc123"}'
    local result
    result="$(_mnemo_parse_json_value "$json" "apiUrl")"
    [[ "$result" == "https://example.com" ]]
}
