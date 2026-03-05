#!/usr/bin/env bash
# hook-guard.sh — Guard wrapper for Stop/PreCompact/PostToolUse hooks.
# Checks if the named handler script exists in ~/.claude/mnemo/hooks-handlers/
# and runs it if found, otherwise exits 0 silently.
#
# Usage: bash hook-guard.sh <script-name>
#   e.g. bash hook-guard.sh stop-check
#        bash hook-guard.sh precompact-check
#        bash hook-guard.sh plan-accepted-check

set -euo pipefail

SCRIPT_NAME="${1:-}"

if [[ -z "$SCRIPT_NAME" ]]; then
    exit 0
fi

TARGET="${HOME}/.claude/mnemo/hooks-handlers/${SCRIPT_NAME}.sh"

if [[ -f "$TARGET" ]]; then
    exec bash "$TARGET"
fi

exit 0
