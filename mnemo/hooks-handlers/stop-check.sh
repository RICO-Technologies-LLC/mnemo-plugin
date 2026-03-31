#!/usr/bin/env bash
# stop-check.sh — Stop hook: prompts to save memories before session exit.
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

CONTEXT='REQUIRED: Before this session ends, review the conversation for decisions, conventions, issues, bugs, or facts worth persisting. For each one, call save-memory.sh:\n\nbash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/save-memory.sh\" \\\n  --tier \"<tier>\" --category \"<category>\" --scope \"<scope>\" \\\n  --topic \"<short title>\" --content \"<declarative summary>\" \\\n  --source \"claude\" --working-dir \"$PWD\" --session-id \"$CLAUDE_SESSION_ID\"\n\nTier guide: Foundation=core values/identity (rare), Strategic=conventions/processes (1yr), Operational=working knowledge/decisions (3mo), Tactical=this week'\''s context (7d), Momentary=right now (8hr).\nCategories: Decision, Fact, Convention, Issue.\n\nWrite content as short declarative statements, like briefing a new team member. Lead with DECISION:/FACT:/CONVENTION:/ISSUE: prefix.\n\nSkip ONLY if the session was trivial (health checks, greetings, no substantive work). If any real work was done, save at least one memory. Run saves in the background (run_in_background: true).'

printf '{"decision":"block","reason":"Saving session memories before exit...","systemMessage":"%s"}' "$CONTEXT"
exit 2
