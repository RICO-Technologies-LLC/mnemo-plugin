#!/usr/bin/env bash
# link-memories.sh — Create an associative link between two memories.
# Usage: bash link-memories.sh <SOURCE_ID> <TARGET_ID> <LINK_TYPE>

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

SOURCE_ID="${1:-}"
TARGET_ID="${2:-}"
LINK_TYPE="${3:-}"

if [[ -z "$SOURCE_ID" || -z "$TARGET_ID" || -z "$LINK_TYPE" ]]; then
    echo "Error: Usage: link-memories.sh <source_id> <target_id> <link_type>" >&2
    exit 1
fi

if mnemo_create_link "$SOURCE_ID" "$TARGET_ID" "$LINK_TYPE"; then
    echo "Memories linked."
else
    _mnemo_format_error
    exit 1
fi
