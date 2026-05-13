#!/usr/bin/env bats
# api-health.bats — Live health endpoint checks against integration server.

load '../helpers/test-helper'

INTEGRATION_URL="https://mnemo-integration-d8h6bzh2bxgrc3e4.westus3-01.azurewebsites.net"

@test "health endpoint returns 200" {
    local code
    code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 25 "${INTEGRATION_URL}/api/health")"
    [[ "$code" == "200" ]]
}

@test "db health endpoint returns 200" {
    local code
    code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 25 "${INTEGRATION_URL}/api/health/db")"
    [[ "$code" == "200" ]]
}
