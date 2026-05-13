#!/usr/bin/env bash
# test-helper.sh — Common setup for all BATS test files.
# Source via: load '../helpers/test-helper'

# Load BATS libraries
load '../libs/bats-support/load'
load '../libs/bats-assert/load'

# Set plugin root to the repo's mmry/ directory
# Allow override via env var (set in run-tests.sh or manually)
if [[ -z "${PLUGIN_ROOT:-}" ]]; then
    PLUGIN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
fi
export PLUGIN_ROOT
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

# Temp directory for test artifacts
export TEST_TMPDIR
TEST_TMPDIR="$(mktemp -d)"

# Override TMPDIR so scripts write to test-controlled location
export TMPDIR="$TEST_TMPDIR"
export MMRY_TMPDIR="$TEST_TMPDIR"

# Disable any real config from interfering
export MMRY_CONFIG_FILE="$TEST_TMPDIR/mmry-config.json"
export MMRY_API_URL=""
export MMRY_API_KEY=""
export MMRY_AUTH_METHOD=""

# Clean up after each test
teardown() {
    rm -rf "$TEST_TMPDIR"
}
