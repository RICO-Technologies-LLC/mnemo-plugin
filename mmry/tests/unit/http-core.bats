#!/usr/bin/env bats
# http-core.bats — Test _mnemo_request with mock curl.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    export MNEMO_API_KEY="test-key"
    export MNEMO_AUTH_METHOD="apikey"
    export MNEMO_API_URL="http://localhost:5291"
    setup_mock_curl
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
}

@test "request: returns 0 for 200 response" {
    run _mnemo_request GET "/api/health"
    [[ "$status" -eq 0 ]]
}

@test "request: returns 0 for 201 response" {
    run _mnemo_request POST "/api/memories" '{"topic":"test"}'
    [[ "$status" -eq 0 ]]
}

@test "request: returns 0 for 204 response" {
    run _mnemo_request POST "/api/memories/1/reinforce"
    [[ "$status" -eq 0 ]]
}

@test "request: returns 1 for 500 response" {
    export MOCK_CURL_HTTP_CODE="500"
    export MOCK_CURL_RESPONSE='{"error":"server error"}'
    run _mnemo_request GET "/api/unknown-path"
    [[ "$status" -eq 1 ]]
}

@test "request: returns 1 for 400 response" {
    export MOCK_CURL_HTTP_CODE="400"
    export MOCK_CURL_RESPONSE='{"error":"bad request"}'
    run _mnemo_request POST "/api/memories" '{}'
    [[ "$status" -eq 1 ]]
}

@test "request: sets MNEMO_HTTP_CODE correctly" {
    _mnemo_request GET "/api/health"
    [[ "$MNEMO_HTTP_CODE" == "200" ]]
}

@test "request: sets MNEMO_RESPONSE correctly" {
    _mnemo_request GET "/api/health"
    [[ "$MNEMO_RESPONSE" == '{"status":"Healthy"}' ]]
}

@test "request: handles auth failure (no key) gracefully" {
    MNEMO_API_KEY=""
    MNEMO_AUTH_METHOD=""
    run _mnemo_request GET "/api/memories"
    [[ "$status" -eq 1 ]]
}

@test "request: logs curl call to curl-log.txt" {
    _mnemo_request GET "/api/health"
    [[ -f "$TEST_TMPDIR/curl-log.txt" ]]
    grep -q "GET.*health" "$TEST_TMPDIR/curl-log.txt"
}

@test "request: sends POST body for create operations" {
    _mnemo_request POST "/api/memories" '{"topic":"hello"}'
    grep -q 'POST.*memories' "$TEST_TMPDIR/curl-log.txt"
}
