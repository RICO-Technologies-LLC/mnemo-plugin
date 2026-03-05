#!/usr/bin/env bash
# save-memory.sh — Store a new memory via Mnemo API.
# Usage: bash save-memory.sh --tier T --category C --scope S --topic T --content C [options]

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

# Parse arguments
TIER="" CATEGORY="" SCOPE="" TOPIC="" CONTENT="" SOURCE=""
TASK_ID="" WORKING_DIR="" PROJECT_ID="" SESSION_ID=""
VISIBILITY="" PERMISSION_GROUP_ID="" SUPERSEDES=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tier)         TIER="$2"; shift 2 ;;
        --category)     CATEGORY="$2"; shift 2 ;;
        --scope)        SCOPE="$2"; shift 2 ;;
        --topic)        TOPIC="$2"; shift 2 ;;
        --content)      CONTENT="$2"; shift 2 ;;
        --source)       SOURCE="$2"; shift 2 ;;
        --task-id)      TASK_ID="$2"; shift 2 ;;
        --working-dir)  WORKING_DIR="$2"; shift 2 ;;
        --project-id)   PROJECT_ID="$2"; shift 2 ;;
        --session-id)   SESSION_ID="$2"; shift 2 ;;
        --visibility)   VISIBILITY="$2"; shift 2 ;;
        --permission-group-id) PERMISSION_GROUP_ID="$2"; shift 2 ;;
        --supersedes)   SUPERSEDES="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# Default working directory from session launch dir if not provided
if [[ -z "$WORKING_DIR" ]]; then
    WORKING_DIR="$(cat "${TMPDIR:-/tmp}/mnemo-session-dir" 2>/dev/null || echo "$PWD")"
fi

# Validate required fields
if [[ -z "$TIER" || -z "$CATEGORY" || -z "$SCOPE" || -z "$TOPIC" || -z "$CONTENT" ]]; then
    echo "Error: --tier, --category, --scope, --topic, and --content are required" >&2
    exit 1
fi

if mnemo_create_memory "$TIER" "$CATEGORY" "$SCOPE" "$TOPIC" "$CONTENT" \
    "$SOURCE" "$TASK_ID" "$WORKING_DIR" "$PROJECT_ID" "$SESSION_ID" \
    "$VISIBILITY" "$PERMISSION_GROUP_ID" "$SUPERSEDES"; then

    echo "Memory saved."
else
    _mnemo_format_error
    exit 1
fi
