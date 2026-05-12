#!/usr/bin/env bash
# stop-check.sh — Stop hook: sends session context to Mnemo API for memory processing.
# Uses temp marker file to debounce (120-second window).
#
# Output contract (#29854):
#   The block message must read as a DIRECTIVE to the model, not as a status line.
#   The model has historically replied "Acknowledged" to status-style block messages
#   without ever calling process-context.sh, so the session ended without a summary
#   reaching the server. The wording below leads with "BLOCKED:", uses imperative
#   phrasing, contains the full process-context.sh command with all required flags,
#   and explicitly forbids "Acknowledged"-style responses.

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

# Directive-style block message. Lines are escaped \n so the JSON parser produces
# real newlines in the system reminder shown to the model.
CONTEXT='BLOCKED: This session cannot end until a Mnemo session summary has been POSTed to the server.\n\nYou MUST do this now, before responding to the user:\n\n1. Write a comprehensive summary of this session. Include every decision, finding, action, and outcome. Treat it as a briefing for someone who was not in the session.\n\n2. POST it by running this command IN THE BACKGROUND (run_in_background: true):\n\nbash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/process-context.sh\" \\\n  --hook-type \"stop\" \\\n  --context \"<your comprehensive session summary here>\" \\\n  --working-dir \"$PWD\" \\\n  --session-id \"$CLAUDE_SESSION_ID\"\n\nThe server decides what to save. Do NOT reply with \"Acknowledged\" or any other status text. Call the script and let it run in the background; the session unblocks once the call is in flight.'

printf '{"decision":"block","reason":"BLOCKED: Save session summary to Mnemo before exit. Run process-context.sh in the background.","systemMessage":"%s"}' "$CONTEXT"
exit 2
