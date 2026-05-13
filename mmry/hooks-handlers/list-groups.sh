#!/usr/bin/env bash
# list-groups.sh — List permission groups the current user belongs to.
# Usage: bash list-groups.sh

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

if mnemo_get_my_groups; then
    if command -v jq &>/dev/null; then
        count="$(echo "$MNEMO_RESPONSE" | jq 'length')"
        if [[ "$count" -eq 0 ]]; then
            echo "No groups found. Create one with the API or ask an admin."
        else
            echo "Found ${count} group(s):"
            echo ""
            echo "$MNEMO_RESPONSE" | jq -r '.[] | "  ID: \(.id)  Name: \(.groupName)"'
        fi
    else
        echo "Groups:"
        echo "$MNEMO_RESPONSE"
    fi
else
    _mnemo_format_error "list groups"
    exit 1
fi
