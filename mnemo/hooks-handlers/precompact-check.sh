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

CONTEXT='REQUIRED: Context compression is imminent. Save a Momentary memory capturing your current session state so you can resume after compression.\n\nbash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/save-memory.sh\" \\\n  --tier \"Momentary\" --category \"Fact\" --scope \"<relevant scope>\" \\\n  --topic \"Session Continuity\" --content \"<what you are working on, current step, key decisions made, what is next>\" \\\n  --source \"claude\" --working-dir \"$PWD\" --session-id \"$CLAUDE_SESSION_ID\"\n\nThe content should be a concise briefing that lets your post-compression self pick up exactly where you left off. Include: (1) what task you are working on, (2) what step you are on, (3) key decisions or findings so far, (4) what to do next.\n\nSkip ONLY if the session context is trivial (no substantive work in progress). Run in background (run_in_background: true).'

printf '{"decision":"block","reason":"Saving session continuity before context compression...","systemMessage":"%s"}' "$CONTEXT"
exit 2
