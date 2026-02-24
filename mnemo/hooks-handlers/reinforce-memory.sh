#!/usr/bin/env bash
# reinforce-memory.sh — Reinforce (reset expiration) for a specific memory.
# Usage: bash reinforce-memory.sh <MEMORY_ID>

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

ID="${1:-}"
if [[ -z "$ID" ]]; then
    echo "Error: Memory ID required as first argument" >&2
    exit 1
fi

if mnemo_reinforce_memory "$ID"; then
    echo "Reinforced memory ID: ${ID}"
else
    echo "Error (HTTP ${MNEMO_HTTP_CODE}): ${MNEMO_RESPONSE}" >&2
    exit 1
fi
