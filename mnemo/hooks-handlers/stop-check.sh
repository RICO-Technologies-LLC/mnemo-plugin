#!/usr/bin/env bash
# stop-check.sh — Stop hook: sends session context to Mnemo API for memory processing.
# Uses temp marker file to debounce (120-second window).

set -euo pipefail

TMPDIR="${TMPDIR:-/tmp}"
MARKER="${TMPDIR}/.mnemo-stop-checked"

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
        exit 0
    fi
fi

touch "$MARKER"

CONTEXT='REQUIRED: Before this session ends, write a comprehensive summary of this session. Include everything that happened — every decision, finding, action, and outcome. Then send it to the Mnemo API.\n\nCall the process endpoint:\n\nbash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/process-context.sh\" \\\n  --hook-type \"stop\" \\\n  --context \"<your comprehensive session summary>\" \\\n  --working-dir \"$PWD\" \\\n  --session-id \"$CLAUDE_SESSION_ID\"\n\nWrite the summary as if briefing someone who was not in the session. Be thorough — the server will decide what to save.\n\nRun in the background (run_in_background: true).'

printf '{"decision":"block","reason":"Mnemo: saving important memories...","systemMessage":"%s"}' "$CONTEXT"
exit 2
