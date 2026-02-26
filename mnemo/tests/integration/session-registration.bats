#!/usr/bin/env bats
# session-registration.bats — Register session and list active sessions (live API).

load '../helpers/test-helper'

INTEGRATION_URL="https://mnemo-integration-d8h6bzh2bxgrc3e4.westus3-01.azurewebsites.net"

_api() {
    local method="$1" path="$2" body="${3:-}"
    local curl_args=(-s -w '\n%{http_code}' --connect-timeout 10 --max-time 25
        -X "$method"
        -H "X-Api-Key: ${MNEMO_INTEGRATION_API_KEY}"
        -H "Content-Type: application/json")
    [[ -n "$body" ]] && curl_args+=(-d "$body")
    curl "${curl_args[@]}" "${INTEGRATION_URL}${path}"
}

@test "sessions: register a session (201)" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    local session_id="bats-test-$(date +%s)"
    echo "$session_id" > "$BATS_FILE_TMPDIR/session_id"
    local response
    response="$(_api POST "/api/sessions" "{\"sessionId\":\"${session_id}\",\"clientName\":\"bats-test\",\"workingDirectory\":\"/tmp/test\"}")"
    local code
    code="$(echo "$response" | tail -1)"
    [[ "$code" == "201" ]]
}

@test "sessions: list active sessions includes registered session" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    [[ ! -f "$BATS_FILE_TMPDIR/session_id" ]] && skip "No session ID"
    local session_id
    session_id="$(cat "$BATS_FILE_TMPDIR/session_id")"
    local response
    response="$(_api GET "/api/sessions/active")"
    local code
    code="$(echo "$response" | tail -1)"
    local body
    body="$(echo "$response" | sed '$d')"
    [[ "$code" == "200" ]]
    [[ "$body" == *"$session_id"* ]]
}

@test "sessions: re-register same session ID updates it" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    [[ ! -f "$BATS_FILE_TMPDIR/session_id" ]] && skip "No session ID"
    local session_id
    session_id="$(cat "$BATS_FILE_TMPDIR/session_id")"
    local response
    response="$(_api POST "/api/sessions" "{\"sessionId\":\"${session_id}\",\"clientName\":\"bats-test-updated\",\"workingDirectory\":\"/tmp/test2\"}")"
    local code
    code="$(echo "$response" | tail -1)"
    [[ "$code" == "201" ]]
}
