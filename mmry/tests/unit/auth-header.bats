#!/usr/bin/env bats
# auth-header.bats — Test _mnemo_get_auth_header.

load '../helpers/test-helper'
load '../helpers/mock-config'

setup() {
    export MNEMO_API_URL="http://localhost:5291"
    setup_mock_curl
}

@test "auth_header: returns X-Api-Key header for apikey auth" {
    export MNEMO_API_KEY="my-secret-key"
    export MNEMO_AUTH_METHOD="apikey"
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"

    local header
    header="$(_mnemo_get_auth_header)"
    [[ "$header" == "X-Api-Key: my-secret-key" ]]
}

@test "auth_header: returns error when no API key configured" {
    export MNEMO_API_KEY=""
    export MNEMO_AUTH_METHOD=""
    # Override HOME so mnemo_load_config doesn't find real config
    export HOME="$TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
    # Force clear after source in case anything leaked
    MNEMO_API_KEY=""
    MNEMO_AUTH_METHOD=""

    run _mnemo_get_auth_header
    [[ "$status" -ne 0 ]]
}

@test "auth_header: returns error message when no API key" {
    export MNEMO_API_KEY=""
    export MNEMO_AUTH_METHOD=""
    export HOME="$TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
    MNEMO_API_KEY=""
    MNEMO_AUTH_METHOD=""

    # Call directly (not run) to check MNEMO_RESPONSE
    _mnemo_get_auth_header 2>/dev/null && status=0 || status=$?
    [[ "$status" -ne 0 ]]
    [[ "$MNEMO_RESPONSE" == *"No API key"* ]]
}
