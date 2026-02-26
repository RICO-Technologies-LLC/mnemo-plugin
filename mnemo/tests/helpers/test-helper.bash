#!/usr/bin/env bash
# test-helper.sh — Common setup for all BATS test files.
# Source via: load '../helpers/test-helper'

# Load BATS libraries
load '../libs/bats-support/load'
load '../libs/bats-assert/load'

# Set plugin root to the repo's mnemo/ directory
export PLUGIN_ROOT
PLUGIN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

# Temp directory for test artifacts
export TEST_TMPDIR
TEST_TMPDIR="$(mktemp -d)"

# Override TMPDIR so scripts write to test-controlled location
export TMPDIR="$TEST_TMPDIR"
export MNEMO_TMPDIR="$TEST_TMPDIR"

# Disable any real config from interfering
export MNEMO_CONFIG_FILE="$TEST_TMPDIR/mnemo-config.json"
export MNEMO_API_URL=""
export MNEMO_API_KEY=""
export MNEMO_AUTH_METHOD=""

# Clean up after each test
teardown() {
    rm -rf "$TEST_TMPDIR"
}
