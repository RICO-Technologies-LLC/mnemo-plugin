#!/usr/bin/env bats
# setup-register.bats — End-to-end tests for new organization registration flow.

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

@test "register: succeeds with all required fields" {
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Registered successfully"* ]]
    [[ "$output" == *"API key generated"* ]]
    [[ "$output" == *"You're all set"* ]]
}

@test "register: creates config file with correct API URL" {
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local config="$HOME/.claude/mnemo-config.json"
    [[ -f "$config" ]]
    grep -q '"apiUrl"' "$config"
    grep -q 'localhost:5291' "$config"
}

@test "register: config file contains API key from response" {
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local config="$HOME/.claude/mnemo-config.json"
    grep -q '"apiKey"' "$config"
    grep -q 'mock-generated-key-abc123' "$config"
}

@test "register: config file has authMethod = apikey" {
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local config="$HOME/.claude/mnemo-config.json"
    grep -q '"authMethod"' "$config"
    grep -q 'apikey' "$config"
}

@test "register: creates settings.json with script permissions" {
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
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

@test "register: calls register API then apikey API" {
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    # Verify API call order
    grep -q 'POST.*auth/register' "$TEST_TMPDIR/curl-log.txt"
    grep -q 'POST.*auth/apikey' "$TEST_TMPDIR/curl-log.txt"
}

@test "register: register is called before apikey generation" {
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local register_line
    register_line="$(grep -n 'auth/register' "$TEST_TMPDIR/curl-log.txt" | head -1 | cut -d: -f1)"
    local apikey_line
    apikey_line="$(grep -n 'auth/apikey' "$TEST_TMPDIR/curl-log.txt" | head -1 | cut -d: -f1)"
    (( register_line < apikey_line ))
}

@test "register: shows first-session guidance for new orgs" {
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$output" == *"first session"* ]]
}

# ── Error Paths ──

@test "register: fails on duplicate email (409)" {
    _mock_endpoint "register" "409" '{"error":"Email already registered"}'
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "duplicate@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"already registered"* ]]
}

@test "register: fails on validation error (400)" {
    _mock_endpoint "register" "400" '{"error":"Password does not meet requirements"}'
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "weak" \
        --api-url "http://localhost:5291"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Validation failed"* ]] || [[ "$output" == *"Error"* ]]
}

@test "register: fails on server error (500)" {
    _mock_endpoint "register" "500" '{"error":"Internal server error"}'
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"failed"* ]]
}

@test "register: fails when API key generation fails" {
    _mock_endpoint "apikey" "500" '{"error":"Could not generate key"}'
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"API key generation failed"* ]]
}

# ── Missing Fields ──

@test "register: fails with missing --name in non-interactive mode" {
    # In non-interactive mode (piped input), if name is missing the script prompts
    # then reads empty from stdin and errors
    run bash "$SETUP_SCRIPT" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" <<< ""
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"required"* ]] || [[ "$output" == *"Error"* ]]
}

@test "register: fails with missing --email" {
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" <<< ""
    [[ "$status" -ne 0 ]]
}

@test "register: fails with missing --password" {
    run bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --api-url "http://localhost:5291" <<< ""
    [[ "$status" -ne 0 ]]
}

# ── Edge Cases ──

@test "register: handles special characters in org name" {
    run bash "$SETUP_SCRIPT" \
        --name "O'Brien & Associates \"LLC\"" \
        --email "admin@obrien.com" \
        --first-name "Sean" \
        --last-name "O'Brien" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291"
    [[ "$status" -eq 0 ]]
    # Verify the register API was called (body should have escaped values)
    grep -q 'POST.*auth/register' "$TEST_TMPDIR/curl-log.txt"
}

@test "register: --help shows usage and exits 0" {
    run bash "$SETUP_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"Register"* ]] || [[ "$output" == *"register"* ]]
}

@test "register: unknown argument fails" {
    run bash "$SETUP_SCRIPT" --unknown-flag
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Unknown argument"* ]]
}

@test "register: custom --api-url is used in API calls" {
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://custom-server:9999" 2>&1

    grep -q 'custom-server:9999' "$TEST_TMPDIR/curl-log.txt"
}

@test "register: preserves existing settings.json content" {
    # This test requires jq to merge permissions into existing settings.json
    # The setup script's Python fallback has issues on Windows Store aliases
    if ! command -v jq &>/dev/null; then
        skip "Requires jq for reliable settings.json merge"
    fi

    # Create a settings file with existing content
    cat > "$HOME/.claude/settings.json" << 'EOF'
{
  "theme": "dark",
  "permissions": {
    "allow": ["Bash(git *)"]
  }
}
EOF
    bash "$SETUP_SCRIPT" \
        --name "Test Corp" \
        --email "admin@testcorp.com" \
        --first-name "Alice" \
        --last-name "Smith" \
        --password "SecurePass1!" \
        --api-url "http://localhost:5291" 2>&1

    local settings="$HOME/.claude/settings.json"
    # New permissions should be added
    grep -q 'save-memory.sh' "$settings"
    # Existing permission should still be there
    grep -q 'git' "$settings"
}
