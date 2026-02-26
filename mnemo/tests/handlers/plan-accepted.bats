#!/usr/bin/env bats
# plan-accepted.bats — Test plan-accepted-check.sh output.

load '../helpers/test-helper'

@test "plan-accepted: outputs block JSON with decision" {
    run bash "$PLUGIN_ROOT/hooks-handlers/plan-accepted-check.sh"
    [[ "$output" == *'"decision":"block"'* ]]
}

@test "plan-accepted: includes reason about saving plan" {
    run bash "$PLUGIN_ROOT/hooks-handlers/plan-accepted-check.sh"
    [[ "$output" == *'PLAN ACCEPTED'* ]]
}

@test "plan-accepted: exits with code 2" {
    run bash "$PLUGIN_ROOT/hooks-handlers/plan-accepted-check.sh"
    [[ "$status" -eq 2 ]]
}
