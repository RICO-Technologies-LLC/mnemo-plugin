#!/usr/bin/env bats
# links.bats — Create link, get related, delete link (live API).

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

_extract_id() {
    local body="$1"
    if command -v jq &>/dev/null; then
        echo "$body" | jq -r '.id'
    else
        echo "$body" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://'
    fi
}

setup_file() {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && return

    # Create two memories to link
    local ts
    ts="$(date +%s)"

    local resp1
    resp1="$(_api POST "/api/memories" "{\"memoryTier\":\"Momentary\",\"category\":\"Fact\",\"scope\":\"test\",\"topic\":\"LinkSource-${ts}\",\"content\":\"Source memory for link test\"}")"
    local body1
    body1="$(echo "$resp1" | sed '$d')"
    echo "$(_extract_id "$body1")" > "$BATS_FILE_TMPDIR/link_source_id"

    local resp2
    resp2="$(_api POST "/api/memories" "{\"memoryTier\":\"Momentary\",\"category\":\"Fact\",\"scope\":\"test\",\"topic\":\"LinkTarget-${ts}\",\"content\":\"Target memory for link test\"}")"
    local body2
    body2="$(echo "$resp2" | sed '$d')"
    echo "$(_extract_id "$body2")" > "$BATS_FILE_TMPDIR/link_target_id"
}

@test "links: create link (201)" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    [[ ! -f "$BATS_FILE_TMPDIR/link_source_id" ]] && skip "No source memory"
    local src
    src="$(cat "$BATS_FILE_TMPDIR/link_source_id")"
    local tgt
    tgt="$(cat "$BATS_FILE_TMPDIR/link_target_id")"
    local response
    response="$(_api POST "/api/memories/${src}/links" "{\"targetMemoryId\":${tgt},\"linkType\":\"related\"}")"
    local code
    code="$(echo "$response" | tail -1)"
    [[ "$code" == "201" ]]
}

@test "links: get related returns linked memory" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    [[ ! -f "$BATS_FILE_TMPDIR/link_source_id" ]] && skip "No source memory"
    local src
    src="$(cat "$BATS_FILE_TMPDIR/link_source_id")"
    local tgt
    tgt="$(cat "$BATS_FILE_TMPDIR/link_target_id")"
    local response
    response="$(_api GET "/api/memories/${src}/related")"
    local code
    code="$(echo "$response" | tail -1)"
    local body
    body="$(echo "$response" | sed '$d')"
    [[ "$code" == "200" ]]
    [[ "$body" == *"$tgt"* ]] || [[ "$body" == *"LinkTarget"* ]]
}

@test "links: delete link (204)" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    [[ ! -f "$BATS_FILE_TMPDIR/link_source_id" ]] && skip "No source memory"
    local src
    src="$(cat "$BATS_FILE_TMPDIR/link_source_id")"
    local tgt
    tgt="$(cat "$BATS_FILE_TMPDIR/link_target_id")"
    local response
    response="$(_api DELETE "/api/memories/${src}/links/${tgt}")"
    local code
    code="$(echo "$response" | tail -1)"
    [[ "$code" == "204" ]]
}

@test "links: get related returns empty after deletion" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    [[ ! -f "$BATS_FILE_TMPDIR/link_source_id" ]] && skip "No source memory"
    local src
    src="$(cat "$BATS_FILE_TMPDIR/link_source_id")"
    local response
    response="$(_api GET "/api/memories/${src}/related")"
    local code
    code="$(echo "$response" | tail -1)"
    local body
    body="$(echo "$response" | sed '$d')"
    [[ "$code" == "200" ]]
    [[ "$body" == "[]" ]]
}

# Cleanup
teardown_file() {
    if [[ -n "${MNEMO_INTEGRATION_API_KEY:-}" ]]; then
        [[ -f "$BATS_FILE_TMPDIR/link_source_id" ]] && _api DELETE "/api/memories/$(cat "$BATS_FILE_TMPDIR/link_source_id")" > /dev/null 2>&1 || true
        [[ -f "$BATS_FILE_TMPDIR/link_target_id" ]] && _api DELETE "/api/memories/$(cat "$BATS_FILE_TMPDIR/link_target_id")" > /dev/null 2>&1 || true
    fi
}
