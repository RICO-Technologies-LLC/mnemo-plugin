#!/usr/bin/env bats
# unicode-support.bats — Test UTF-8 handling in JSON helpers.

load '../helpers/test-helper'

setup() {
    export MNEMO_API_KEY="test-key"
    export MNEMO_AUTH_METHOD="apikey"
    export MNEMO_API_URL="http://localhost:5291"
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
}

# ── _mnemo_json_escape with unicode ──

@test "json_escape: preserves ASCII text" {
    local result
    result="$(_mnemo_json_escape 'hello world')"
    [[ "$result" == 'hello world' ]]
}

@test "json_escape: preserves accented characters" {
    local result
    result="$(_mnemo_json_escape 'café résumé')"
    [[ "$result" == 'café résumé' ]]
}

@test "json_escape: preserves CJK characters" {
    local result
    result="$(_mnemo_json_escape '日本語テスト')"
    [[ "$result" == '日本語テスト' ]]
}

@test "json_escape: preserves emoji" {
    local result
    result="$(_mnemo_json_escape 'test 🧠 memory')"
    [[ "$result" == 'test 🧠 memory' ]]
}

@test "json_escape: uses printf not echo (no -n mangling)" {
    # Verify the function produces output via printf (not echo -n)
    # by checking it handles a string starting with -n correctly
    local result
    result="$(_mnemo_json_escape '-n test')"
    [[ "$result" == '-n test' ]]
}

# ── _mnemo_build_json with unicode values ──

@test "build_json: handles unicode values" {
    local result
    result="$(_mnemo_build_json "topic" "café" "content" "résumé")"
    [[ "$result" == '{"topic":"café","content":"résumé"}' ]]
}

@test "build_json: handles mixed unicode and escapes" {
    local result
    result="$(_mnemo_build_json "content" 'He said "café"')"
    [[ "$result" == '{"content":"He said \"café\""}' ]]
}
