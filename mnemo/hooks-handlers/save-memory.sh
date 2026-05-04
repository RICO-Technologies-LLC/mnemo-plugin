#!/usr/bin/env bash
# save-memory.sh — Send context to Mnemo API for server-side processing.
# Thin client: the server decides tier, category, scope, and formatting.
# Usage: bash save-memory.sh --context "..." [--working-dir DIR] [--session-id ID]

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

# Parse arguments ��� accept both new and legacy formats
CONTEXT="" WORKING_DIR="" SESSION_ID="" PROJECT_ID="" TASK_ID=""

# Legacy arguments (ignored — server classifies now)
TIER="" CATEGORY="" SCOPE="" TOPIC="" CONTENT="" SOURCE=""
VISIBILITY="" PERMISSION_GROUP_ID="" SUPERSEDES=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --context)      CONTEXT="$2"; shift 2 ;;
        --working-dir)  WORKING_DIR="$2"; shift 2 ;;
        --session-id)   SESSION_ID="$2"; shift 2 ;;
        --project-id)   PROJECT_ID="$2"; shift 2 ;;
        --task-id)      TASK_ID="$2"; shift 2 ;;
        # Legacy arguments — build context from them for backward compatibility
        --tier)         TIER="$2"; shift 2 ;;
        --category)     CATEGORY="$2"; shift 2 ;;
        --scope)        SCOPE="$2"; shift 2 ;;
        --topic)        TOPIC="$2"; shift 2 ;;
        --content)      CONTENT="$2"; shift 2 ;;
        --source)       SOURCE="$2"; shift 2 ;;
        --visibility)   VISIBILITY="$2"; shift 2 ;;
        --permission-group-id) PERMISSION_GROUP_ID="$2"; shift 2 ;;
        --supersedes)   SUPERSEDES="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# Default working directory
if [[ -z "$WORKING_DIR" ]]; then
    WORKING_DIR="$(cat "${TMPDIR:-/tmp}/mnemo-session-dir" 2>/dev/null || echo "$PWD")"
fi

# If legacy arguments were used, build context from them
if [[ -z "$CONTEXT" && -n "$TOPIC" && -n "$CONTENT" ]]; then
    CONTEXT="Memory to save — Topic: ${TOPIC}. Content: ${CONTENT}."
    [[ -n "$TIER" ]] && CONTEXT="${CONTEXT} Suggested tier: ${TIER}."
    [[ -n "$CATEGORY" ]] && CONTEXT="${CONTEXT} Suggested category: ${CATEGORY}."
    [[ -n "$SCOPE" ]] && CONTEXT="${CONTEXT} Scope: ${SCOPE}."
fi

if [[ -z "$CONTEXT" ]]; then
    echo "Error: --context is required (or legacy --topic and --content)" >&2
    exit 1
fi

if mnemo_process_context "$CONTEXT" "manual" "$WORKING_DIR" "$SESSION_ID" "$PROJECT_ID" "$TASK_ID" "$VISIBILITY" "$PERMISSION_GROUP_ID"; then
    echo "Memory sent to Mnemo for processing."
else
    _mnemo_format_error "save"
    exit 1
fi
