#!/usr/bin/env bash
# precompact-check.sh — PreCompact hook: prompts to save session continuity before compression.
# Uses temp marker file to debounce (120-second window).

set -euo pipefail

TMPDIR="${TMPDIR:-/tmp}"
MARKER="${TMPDIR}/.mnemo-precompact-checked"

if [[ -f "$MARKER" ]]; then
    # Check file age — cross-platform
    now=$(date +%s)
    if stat --version &>/dev/null 2>&1; then
        # GNU stat
        mtime=$(stat -c %Y "$MARKER" 2>/dev/null || echo 0)
    else
        # BSD stat (macOS)
        mtime=$(stat -f %m "$MARKER" 2>/dev/null || echo 0)
    fi
    age=$(( now - mtime ))
    if (( age < 120 )); then
        rm -f "$MARKER"
        exit 0
    fi
fi

touch "$MARKER"
printf '{"decision":"block","reason":"CONTEXT COMPRESSION IMMINENT — Saved a Momentary memory with Topic Session Continuity, Category Fact, and Content describing what you are working on, what step you are on, and key decisions made so far. Set WorkingDirectory to your current working directory. Didn'\''t save if context is trivial."}'
exit 2
