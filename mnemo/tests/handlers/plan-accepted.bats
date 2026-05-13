#!/usr/bin/env bats
# plan-accepted.bats — Test plan-accepted-check.sh output.

load '../helpers/test-helper'

@test "plan-accepted: outputs block JSON with decision" {
    run bash "$PLUGIN_ROOT/hooks-handlers/plan-accepted-check.sh"
    [[ "$output" == *'"decision":"block"'* ]]
}

@test "plan-accepted: includes reason about saving plan" {
    run bash "$PLUGIN_ROOT/hooks-handlers/plan-accepted-check.sh"
    # Reason wording was changed from "PLAN ACCEPTED" to a softer status line
    # in the thin-client refactor (v1.4 #29732). Assertion now matches the
    # current production string. Either phrasing should mention saving.
    [[ "$output" == *'saving accepted plan'* ]] || \
    [[ "$output" == *'Saving accepted plan'* ]]
}

@test "plan-accepted: exits with code 2" {
    run bash "$PLUGIN_ROOT/hooks-handlers/plan-accepted-check.sh"
    [[ "$status" -eq 2 ]]
}
