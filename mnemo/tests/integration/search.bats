#!/usr/bin/env bats
# search.bats — Store memory and search by keyword (live API).

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

@test "search: create memory with unique keyword" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    local keyword="BATSUnique$(date +%s)"
    echo "$keyword" > "$BATS_FILE_TMPDIR/search_keyword"
    local response
    response="$(_api POST "/api/memories" "{\"memoryTier\":\"Momentary\",\"category\":\"Fact\",\"scope\":\"test\",\"topic\":\"${keyword}\",\"content\":\"Searchable content with ${keyword}\"}")"
    local code
    code="$(echo "$response" | tail -1)"
    local body
    body="$(echo "$response" | sed '$d')"
    [[ "$code" == "201" ]]

    # Save memory ID for cleanup
    if command -v jq &>/dev/null; then
        echo "$(echo "$body" | jq -r '.id')" > "$BATS_FILE_TMPDIR/search_memory_id"
    else
        echo "$(echo "$body" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')" > "$BATS_FILE_TMPDIR/search_memory_id"
    fi
}

@test "search: find memory by keyword" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    [[ ! -f "$BATS_FILE_TMPDIR/search_keyword" ]] && skip "No keyword"
    local keyword
    keyword="$(cat "$BATS_FILE_TMPDIR/search_keyword")"
    local response
    response="$(_api GET "/api/memories/search?q=${keyword}")"
    local code
    code="$(echo "$response" | tail -1)"
    local body
    body="$(echo "$response" | sed '$d')"
    [[ "$code" == "200" ]]
    [[ "$body" == *"$keyword"* ]]
}

@test "search: no results returns empty array" {
    [[ -z "${MNEMO_INTEGRATION_API_KEY:-}" ]] && skip "No API key"
    local response
    response="$(_api GET "/api/memories/search?q=XYZNonExistentKeyword99999")"
    local code
    code="$(echo "$response" | tail -1)"
    local body
    body="$(echo "$response" | sed '$d')"
    [[ "$code" == "200" ]]
    [[ "$body" == "[]" ]]
}

# Cleanup
teardown_file() {
    if [[ -n "${MNEMO_INTEGRATION_API_KEY:-}" && -f "$BATS_FILE_TMPDIR/search_memory_id" ]]; then
        local mid
        mid="$(cat "$BATS_FILE_TMPDIR/search_memory_id")"
        _api DELETE "/api/memories/${mid}" > /dev/null 2>&1 || true
    fi
}
