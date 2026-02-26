#!/usr/bin/env bats
# setup-join.bats — End-to-end tests for joining an existing organization.

load '../helpers/test-helper'
load '../helpers/mock-config'

SETUP_SCRIPT=""

setup() {
    setup_mock_curl

    # Isolate HOME so setup doesn't touch real config
    export HOME="$TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"

    # Copy setup script to a marketplace-like path so it skips install.sh
    # (the script checks if its path contains /.claude/mnemo/)
    mkdir -p "$HOME/.claude/mnemo/setup"
    cp "$PLUGIN_ROOT/setup/mnemo-setup.sh" "$HOME/.claude/mnemo/setup/"
    chmod +x "$HOME/.claude/mnemo/setup/mnemo-setup.sh"
    SETUP_SCRIPT="$HOME/.claude/mnemo/setup/mnemo-setup.sh"
}

# Helper to set per-endpoint mock overrides
_mock_endpoint() {
    local endpoint="$1" code="$2" body="${3:-}"
    echo "$code" > "$TEST_TMPDIR/mock-override-${endpoint}-code"
    echo "$body" > "$TEST_TMPDIR/mock-override-${endpoint}-body"
}

# ── Happy Path ──

@test "join: succeeds with email and password" {
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Logged in successfully"* ]]
    [[ "$output" == *"API key generated"* ]]
    [[ "$output" == *"You're all set"* ]]
}

@test "join: creates config file with API key" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local config="$HOME/.claude/mnemo-config.json"
    [[ -f "$config" ]]
    grep -q '"apiKey"' "$config"
    grep -q 'mock-generated-key-abc123' "$config"
}

@test "join: config file has correct API URL" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local config="$HOME/.claude/mnemo-config.json"
    grep -q 'localhost:5291' "$config"
}

@test "join: config file has authMethod = apikey" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local config="$HOME/.claude/mnemo-config.json"
    grep -q '"authMethod"' "$config"
    grep -q 'apikey' "$config"
}

@test "join: creates settings.json with script permissions" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local settings="$HOME/.claude/settings.json"
    [[ -f "$settings" ]]
    grep -q 'save-memory.sh' "$settings"
    grep -q 'reinforce-memory.sh' "$settings"
    grep -q 'deactivate-memory.sh' "$settings"
    grep -q 'link-memories.sh' "$settings"
    grep -q 'search-memories.sh' "$settings"
    grep -q 'mnemo-client.sh' "$settings"
}

@test "join: calls login API then apikey API" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    grep -q 'POST.*auth/login' "$TEST_TMPDIR/curl-log.txt"
    grep -q 'POST.*auth/apikey' "$TEST_TMPDIR/curl-log.txt"
    # Should NOT call register
    ! grep -q 'auth/register' "$TEST_TMPDIR/curl-log.txt"
}

@test "join: login is called before apikey generation" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local login_line
    login_line="$(grep -n 'auth/login' "$TEST_TMPDIR/curl-log.txt" | head -1 | cut -d: -f1)"
    local apikey_line
    apikey_line="$(grep -n 'auth/apikey' "$TEST_TMPDIR/curl-log.txt" | head -1 | cut -d: -f1)"
    (( login_line < apikey_line ))
}

@test "join: does NOT show first-session guidance (join users are not new orgs)" {
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    # The "first session" onboarding message is only for register mode
    [[ "$output" != *"first session"* ]]
}

# ── Error Paths ──

@test "join: fails on invalid credentials (401)" {
    _mock_endpoint "login" "401" '{"error":"Invalid credentials"}'
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "wrong@testcorp.com" \
        --password "WrongPass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Invalid email or password"* ]]
}

@test "join: fails on server error (500)" {
    _mock_endpoint "login" "500" '{"error":"Internal server error"}'
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Login failed"* ]]
}

@test "join: fails when API key generation fails" {
    _mock_endpoint "apikey" "500" '{"error":"Could not generate key"}'
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"API key generation failed"* ]]
}

# ── Missing Fields ──

@test "join: fails with missing --email in non-interactive mode" {
    run bash "$SETUP_SCRIPT" \
        --join \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" <<< ""
    [[ "$status" -ne 0 ]]
}

@test "join: fails with missing --password in non-interactive mode" {
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --api-url "http://localhost:5291" <<< ""
    [[ "$status" -ne 0 ]]
}

# ── Edge Cases ──

@test "join: handles special characters in email" {
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "user+test@test-corp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -eq 0 ]]
    grep -q 'POST.*auth/login' "$TEST_TMPDIR/curl-log.txt"
}

@test "join: handles special characters in password" {
    run bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password 'P@$$w0rd!#%^&*' \
        --api-url "http://localhost:5291"
    [[ "$status" -eq 0 ]]
}

@test "join: custom --api-url is used in API calls" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://custom-server:9999" 2>&1

    grep -q 'custom-server:9999' "$TEST_TMPDIR/curl-log.txt"
}

@test "join: config file written to ~/.claude/mnemo-config.json" {
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    [[ -f "$HOME/.claude/mnemo-config.json" ]]
}

@test "join: re-running setup overwrites previous config" {
    # First setup
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://server-one:5291" 2>&1

    # Second setup with different URL
    bash "$SETUP_SCRIPT" \
        --join \
        --email "user@testcorp.com" \
        --password "SecurePass1!" \
        --api-url "http://server-two:5291" 2>&1

    local config="$HOME/.claude/mnemo-config.json"
    grep -q 'server-two' "$config"
    ! grep -q 'server-one' "$config"
}
