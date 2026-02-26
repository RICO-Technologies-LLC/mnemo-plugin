#!/usr/bin/env bats
# config-loading.bats — Test mnemo_load_config with various scenarios.

load '../helpers/test-helper'
load '../helpers/mock-config'

# Reset globals before each test so mnemo_load_config starts fresh
setup() {
    export MNEMO_API_URL=""
    export MNEMO_API_KEY=""
    export MNEMO_AUTH_METHOD=""
    export MNEMO_CONFIG_FILE="$TEST_TMPDIR/mnemo-config.json"
    # Prevent auto-init from sourcing — we'll call mnemo_load_config manually
}

# Helper to source client fresh (it runs mnemo_load_config on source)
_source_client() {
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
}

@test "config: loads apiUrl from config file" {
    create_test_config "https://custom.example.com" "my-key" "apikey"
    _source_client
    [[ "$MNEMO_API_URL" == "https://custom.example.com" ]]
}

@test "config: loads apiKey from config file" {
    create_test_config "http://localhost" "secret-key-42" "apikey"
    _source_client
    [[ "$MNEMO_API_KEY" == "secret-key-42" ]]
}

@test "config: loads authMethod from config file" {
    create_test_config "http://localhost" "key" "apikey"
    _source_client
    [[ "$MNEMO_AUTH_METHOD" == "apikey" ]]
}

@test "config: falls back to default URL when no config" {
    # No config file at $MNEMO_CONFIG_FILE
    rm -f "$MNEMO_CONFIG_FILE"
    _source_client
    [[ "$MNEMO_API_URL" == "https://mnemo-dffsh5b3b6gadpcu.westus3-01.azurewebsites.net" ]]
}

@test "config: auto-detects apikey auth when apiKey is set" {
    cat > "$MNEMO_CONFIG_FILE" <<'EOF'
{
  "apiUrl": "http://localhost",
  "apiKey": "some-key"
}
EOF
    _source_client
    [[ "$MNEMO_AUTH_METHOD" == "apikey" ]]
}

@test "config: env variables override config file values" {
    create_test_config "http://from-config" "config-key" "apikey"
    export MNEMO_API_URL="http://from-env"
    export MNEMO_API_KEY="env-key"
    export MNEMO_AUTH_METHOD="apikey"
    _source_client
    [[ "$MNEMO_API_URL" == "http://from-env" ]]
    [[ "$MNEMO_API_KEY" == "env-key" ]]
}

@test "config: MNEMO_CONFIG_FILE env var takes priority" {
    local alt_config="$TEST_TMPDIR/alt-config.json"
    cat > "$alt_config" <<'EOF'
{
  "apiUrl": "http://alt-server",
  "authMethod": "apikey",
  "apiKey": "alt-key"
}
EOF
    export MNEMO_CONFIG_FILE="$alt_config"
    _source_client
    [[ "$MNEMO_API_URL" == "http://alt-server" ]]
    [[ "$MNEMO_API_KEY" == "alt-key" ]]
}

@test "config: handles missing config file gracefully" {
    export MNEMO_CONFIG_FILE="$TEST_TMPDIR/nonexistent.json"
    _source_client
    # Should use defaults, not error
    [[ "$MNEMO_API_URL" == "https://mnemo-dffsh5b3b6gadpcu.westus3-01.azurewebsites.net" ]]
}

@test "config: plugin root config takes priority over home dir config" {
    # Create config in plugin root
    cat > "$PLUGIN_ROOT/mnemo-config.json" <<'EOF'
{
  "apiUrl": "http://plugin-root-server",
  "authMethod": "apikey",
  "apiKey": "plugin-root-key"
}
EOF
    # Remove MNEMO_CONFIG_FILE so it falls through
    unset MNEMO_CONFIG_FILE
    _source_client
    [[ "$MNEMO_API_URL" == "http://plugin-root-server" ]]

    # Clean up
    rm -f "$PLUGIN_ROOT/mnemo-config.json"
}
