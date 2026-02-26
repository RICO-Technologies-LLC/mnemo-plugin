#!/usr/bin/env bash
# mock-config.sh — Helper functions to create test config files.

# Create a minimal config file with API key auth
# Usage: create_test_config [api_url] [api_key] [auth_method]
create_test_config() {
    local api_url="${1-http://localhost:5291}"
    local api_key="${2-test-api-key-12345}"
    local auth_method="${3-apikey}"
    local config_file="${MNEMO_CONFIG_FILE:-$TEST_TMPDIR/mnemo-config.json}"

    cat > "$config_file" <<EOF
{
  "apiUrl": "${api_url}",
  "authMethod": "${auth_method}",
  "apiKey": "${api_key}"
}
EOF
    echo "$config_file"
}

# Create an empty config file (no API key)
create_empty_config() {
    local config_file="${MNEMO_CONFIG_FILE:-$TEST_TMPDIR/mnemo-config.json}"
    cat > "$config_file" <<EOF
{
  "apiUrl": "http://localhost:5291",
  "authMethod": "",
  "apiKey": ""
}
EOF
    echo "$config_file"
}

# Set up mock curl in PATH
setup_mock_curl() {
    local mock_dir="$TEST_TMPDIR/mock-bin"
    mkdir -p "$mock_dir"
    cp "$BATS_TEST_DIRNAME/../helpers/mock-curl.sh" "$mock_dir/curl"
    chmod +x "$mock_dir/curl"
    export PATH="$mock_dir:$PATH"
}
