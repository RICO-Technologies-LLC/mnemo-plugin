#!/usr/bin/env bash
# process-context.sh — Send session context to Mnemo API for server-side AI processing.
# Usage: bash process-context.sh --hook-type TYPE --context "..." [options]

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

# Parse arguments
HOOK_TYPE="" CONTEXT="" WORKING_DIR="" SESSION_ID="" PROJECT_ID="" TASK_ID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --hook-type)    HOOK_TYPE="$2"; shift 2 ;;
        --context)      CONTEXT="$2"; shift 2 ;;
        --working-dir)  WORKING_DIR="$2"; shift 2 ;;
        --session-id)   SESSION_ID="$2"; shift 2 ;;
        --project-id)   PROJECT_ID="$2"; shift 2 ;;
        --task-id)      TASK_ID="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# Default working directory from session launch dir if not provided
if [[ -z "$WORKING_DIR" ]]; then
    WORKING_DIR="$(cat "${TMPDIR:-/tmp}/mnemo-session-dir" 2>/dev/null || echo "$PWD")"
fi

# Validate required fields
if [[ -z "$HOOK_TYPE" || -z "$CONTEXT" ]]; then
    echo "Error: --hook-type and --context are required" >&2
    exit 1
fi

if mnemo_process_context "$CONTEXT" "$HOOK_TYPE" "$WORKING_DIR" "$SESSION_ID" "$PROJECT_ID" "$TASK_ID"; then
    echo "Context sent to Mnemo for processing."
else
    _mnemo_format_error "process"
    exit 1
fi
