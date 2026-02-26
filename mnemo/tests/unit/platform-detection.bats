#!/usr/bin/env bats
# platform-detection.bats — Test cross-platform date and stat handling.

load '../helpers/test-helper'

setup() {
    export MNEMO_API_KEY="test-key"
    export MNEMO_AUTH_METHOD="apikey"
    export MNEMO_API_URL="http://localhost:5291"
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
}

@test "date +%s returns a reasonable epoch number" {
    local epoch
    epoch="$(date +%s)"
    # Should be a large number (past year 2020 = 1577836800)
    (( epoch > 1577836800 ))
}

@test "stat detects file age correctly" {
    # Create a file and verify we can read its mtime
    local testfile="$TEST_TMPDIR/age-test"
    touch "$testfile"

    local mtime
    if stat --version &>/dev/null 2>&1; then
        mtime=$(stat -c %Y "$testfile" 2>/dev/null || echo 0)
    else
        mtime=$(stat -f %m "$testfile" 2>/dev/null || echo 0)
    fi

    local now
    now=$(date +%s)
    local age=$(( now - mtime ))

    # File was just created, age should be < 5 seconds
    (( age < 5 ))
}
