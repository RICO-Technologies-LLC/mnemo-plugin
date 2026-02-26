#!/usr/bin/env bats
# url-encoding.bats — Test _mnemo_urlencode.

load '../helpers/test-helper'

setup() {
    export MNEMO_API_KEY="test-key"
    export MNEMO_AUTH_METHOD="apikey"
    export MNEMO_API_URL="http://localhost:5291"
    source "$PLUGIN_ROOT/hooks-handlers/mnemo-client.sh"
}

@test "urlencode: encodes spaces as %20" {
    local result
    result="$(_mnemo_urlencode 'hello world')"
    [[ "$result" == 'hello%20world' ]]
}

@test "urlencode: encodes colons" {
    local result
    result="$(_mnemo_urlencode 'C:')"
    [[ "$result" == 'C%3A' ]]
}

@test "urlencode: encodes backslashes" {
    local result
    result="$(_mnemo_urlencode 'C:\Users')"
    [[ "$result" == 'C%3A%5CUsers' ]]
}

@test "urlencode: encodes hash" {
    local result
    result="$(_mnemo_urlencode 'section#2')"
    [[ "$result" == 'section%232' ]]
}

@test "urlencode: encodes query string characters" {
    local result
    result="$(_mnemo_urlencode 'a=1&b=2?c')"
    [[ "$result" == 'a%3D1%26b%3D2%3Fc' ]]
}

@test "urlencode: passes alphanumeric unchanged" {
    local result
    result="$(_mnemo_urlencode 'abcXYZ123')"
    [[ "$result" == 'abcXYZ123' ]]
}

@test "urlencode: handles Windows-style paths" {
    local result
    result="$(_mnemo_urlencode 'C:\Users\eric\project')"
    [[ "$result" == 'C%3A%5CUsers%5Ceric%5Cproject' ]]
}

@test "urlencode: handles empty string" {
    local result
    result="$(_mnemo_urlencode '')"
    [[ "$result" == '' ]]
}
