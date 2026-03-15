#!/usr/bin/env bats
# install-uninstall.bats — Tests for install.sh and uninstall.sh settings.json changes.

load '../helpers/test-helper'

INSTALL_SCRIPT=""
UNINSTALL_SCRIPT=""

setup() {
    # Isolate HOME so scripts don't touch real config
    export HOME="$TEST_TMPDIR/fakehome"
    mkdir -p "$HOME/.claude"

    INSTALL_SCRIPT="$PLUGIN_ROOT/setup/install.sh"
    UNINSTALL_SCRIPT="$PLUGIN_ROOT/setup/uninstall.sh"
}

# ══════════════════════════════════════════════
# install.sh — autoMemoryEnabled
# ══════════════════════════════════════════════

@test "install: sets autoMemoryEnabled to false on fresh install" {
    run bash "$INSTALL_SCRIPT"
    [[ "$status" -eq 0 ]]

    local settings="$HOME/.claude/settings.json"
    [[ -f "$settings" ]]
    run jq '.autoMemoryEnabled' "$settings"
    assert_output "false"
}

@test "install: sets autoMemoryEnabled to false when previously true" {
    echo '{"autoMemoryEnabled": true}' > "$HOME/.claude/settings.json"

    run bash "$INSTALL_SCRIPT"
    [[ "$status" -eq 0 ]]

    run jq '.autoMemoryEnabled' "$HOME/.claude/settings.json"
    assert_output "false"
}

@test "install: preserves existing settings when adding autoMemoryEnabled" {
    echo '{"someOtherSetting": "keep-me"}' > "$HOME/.claude/settings.json"

    run bash "$INSTALL_SCRIPT"
    [[ "$status" -eq 0 ]]

    run jq '.someOtherSetting' "$HOME/.claude/settings.json"
    assert_output '"keep-me"'

    run jq '.autoMemoryEnabled' "$HOME/.claude/settings.json"
    assert_output "false"
}

# ══════════════════════════════════════════════
# uninstall.sh — autoMemoryEnabled cleanup
# ══════════════════════════════════════════════

@test "uninstall: removes autoMemoryEnabled from settings.json" {
    echo '{"autoMemoryEnabled": false, "otherSetting": true}' > "$HOME/.claude/settings.json"

    run bash "$UNINSTALL_SCRIPT"
    [[ "$status" -eq 0 ]]

    run jq 'has("autoMemoryEnabled")' "$HOME/.claude/settings.json"
    assert_output "false"

    run jq '.otherSetting' "$HOME/.claude/settings.json"
    assert_output "true"
}

@test "uninstall: succeeds when autoMemoryEnabled is not present" {
    echo '{"otherSetting": true}' > "$HOME/.claude/settings.json"

    run bash "$UNINSTALL_SCRIPT"
    [[ "$status" -eq 0 ]]

    run jq 'has("autoMemoryEnabled")' "$HOME/.claude/settings.json"
    assert_output "false"
}
