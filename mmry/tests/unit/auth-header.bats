#!/usr/bin/env bats
# auth-header.bats — Test _mmry_get_auth_header.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    export MMRY_API_URL="http://localhost:5291"
    setup_mock_curl
}

@test "auth_header: returns X-Api-Key header for apikey auth" {
    export MMRY_API_KEY="my-secret-key"
    export MMRY_AUTH_METHOD="apikey"
    source "$PLUGIN_ROOT/hooks-handlers/mmry-client.sh"

    local header
    header="$(_mmry_get_auth_header)"
    [[ "$header" == "X-Api-Key: my-secret-key" ]]
}

@test "auth_header: returns error when no API key configured" {
    export MMRY_API_KEY=""
    export MMRY_AUTH_METHOD=""
    # Override HOME so mmry_load_config doesn't find real config
    export HOME="$TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"
    source "$PLUGIN_ROOT/hooks-handlers/mmry-client.sh"
    # Force clear after source in case anything leaked
    MMRY_API_KEY=""
    MMRY_AUTH_METHOD=""

    run _mmry_get_auth_header
    [[ "$status" -ne 0 ]]
}

@test "auth_header: returns error message when no API key" {
    export MMRY_API_KEY=""
    export MMRY_AUTH_METHOD=""
    export HOME="$TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"
    source "$PLUGIN_ROOT/hooks-handlers/mmry-client.sh"
    MMRY_API_KEY=""
    MMRY_AUTH_METHOD=""

    # Call directly (not run) to check MMRY_RESPONSE
    _mmry_get_auth_header 2>/dev/null && status=0 || status=$?
    [[ "$status" -ne 0 ]]
    [[ "$MMRY_RESPONSE" == *"No API key"* ]]
}
