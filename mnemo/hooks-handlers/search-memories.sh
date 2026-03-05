#!/usr/bin/env bash
# search-memories.sh — Search memories by keyword.
# Usage: bash search-memories.sh <KEYWORDS> [SCOPE]

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

KEYWORDS="${1:-}"
SCOPE="${2:-}"

if [[ -z "$KEYWORDS" ]]; then
    echo "Error: Keywords required as first argument" >&2
    exit 1
fi

if mnemo_search_memories "$KEYWORDS" "$SCOPE"; then
    if command -v jq &>/dev/null; then
        count="$(echo "$MNEMO_RESPONSE" | jq 'length')"
        echo "Found ${count} memories:"
        echo ""
        echo "$MNEMO_RESPONSE" | jq -r '.[] | "\(.memoryTier) | \(.scope) | \(.topic)\n  \(.content)\n---"'
    else
        echo "Results:"
        echo "$MNEMO_RESPONSE"
    fi
else
    _mnemo_format_error
    exit 1
fi
