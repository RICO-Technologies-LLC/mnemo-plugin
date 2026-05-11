#!/usr/bin/env bash
# SessionStart hook: loads memories from Mnemo API via curl.
# Outputs hook JSON with path to temp file containing loaded memories.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

# Self-update check — runs before anything else, debounced to once per hour
bash "${PLUGIN_ROOT}/hooks-handlers/self-update.sh" 2>/dev/null || true

source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

WORK_DIR="$PWD"

# Bug #9 (Intervals #29949): read session_id from the SessionStart hook stdin
# payload (always present per the Claude Code hook spec). The CLAUDE_SESSION_ID
# env var is not reliably exported across hook and Bash-tool environments, so
# we treat stdin as the canonical source. The fallback chain ends at "unknown"
# only when the script is invoked outside a hook context (e.g., manual tests).
HOOK_PAYLOAD="$(cat 2>/dev/null || echo '{}')"
SESSION_ID=""
if command -v jq &>/dev/null; then
    SESSION_ID="$(printf '%s' "$HOOK_PAYLOAD" | jq -r '.session_id // empty' 2>/dev/null || true)"
fi
if [[ -z "$SESSION_ID" ]]; then
    # jq missing or stdin not JSON — fall back to env var, then to "unknown".
    SESSION_ID="$(printf '%s' "$HOOK_PAYLOAD" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
    SESSION_ID="${SESSION_ID:-${CLAUDE_SESSION_ID:-unknown}}"
fi

# NOTE: Bug #9 fix removed the /tmp/mnemo-session-dir and
# /tmp/mnemo-session-dir-${SESSION_ID} writes that previously lived here.
# Working directory is now persisted server-side via the /api/sessions POST
# below; save-memory.sh resolves it back from the API when needed.

# Check if config is loaded — guide unconfigured users to run setup
if [[ -z "${MNEMO_API_KEY:-}" ]]; then
    API_URL="https://mmryai.com"
    # shellcheck disable=SC2016
    SETUP_MSG='MMRY AI is installed but needs to be set up. Run the setup script to authenticate via the browser.

## Setup

Run this command using the Bash tool:

bash ~/.claude/mnemo/setup/mnemo-setup.sh

This will open a browser window where the user can log in or create an account on mmryai.com. Once they authorize, the script writes the config file and permissions automatically.

If the browser does not open, the script prints a URL the user can copy and paste.

After setup completes, tell the user: "You are all set. Restart Claude Code and your memories will start loading automatically." Mention /mnemo:help for a quick reference.

If the user does not have an account yet, direct them to https://mmryai.com to sign up first, then run setup again.'

    # Escape for JSON output
    SETUP_MSG_ESCAPED="$(printf '%s' "$SETUP_MSG" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')"
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$SETUP_MSG_ESCAPED"
    exit 0
fi

MEM_FILE="${MNEMO_TMPDIR}/mnemo-memories.md"

# Load startup memories
if ! mnemo_get_startup_memories "$WORK_DIR"; then
    if [[ "${MNEMO_HTTP_CODE:-}" == "403" ]]; then
        printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Mnemo trial has expired. Inform the user that their free trial has ended and they need to upgrade to continue using memory features."}}'
        exit 0
    fi
    if [[ "${MNEMO_HTTP_CODE:-}" == "402" ]]; then
        printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Mnemo credits exhausted. Inform the user their API credits have run out. Visit https://mmryai.com to add more credits or upgrade their plan."}}'
        exit 0
    fi
    escaped_err="$(echo "$MNEMO_RESPONSE" | sed "s/\"/'/g" | sed 's/\\/\\\\/g')"
    printf '{"error":"session-start failed: %s"}' "$escaped_err"
    exit 0
fi

# Parse JSON response into markdown (disable pipefail — grep returns 1 on no match)
set +o pipefail
{
    echo "# Mnemo — Loaded Memories"
    echo ""

    if command -v jq &>/dev/null; then
        local_count="$(echo "$MNEMO_RESPONSE" | jq 'length')"
        echo "$MNEMO_RESPONSE" | jq -r '.[] | to_entries | map(.key + ": " + (.value | tostring)) | join("\n"), "---"'
    else
        # Grep/sed fallback for flat JSON arrays
        local_count=0
        # Count objects by counting "id" fields
        local_count="$(echo "$MNEMO_RESPONSE" | { grep -o '"id"' || true; } | wc -l | tr -d ' ')"

        # Simple line-by-line extraction — works for flat JSON arrays
        echo "$MNEMO_RESPONSE" | sed 's/},{/}\n{/g' | sed 's/^\[//;s/\]$//' | while IFS= read -r obj; do
            [[ -z "$obj" || "$obj" == "[" || "$obj" == "]" ]] && continue
            # Extract key-value pairs
            echo "$obj" | { grep -o '"[^"]*":"[^"]*"\|"[^"]*":[0-9]*\|"[^"]*":null\|"[^"]*":true\|"[^"]*":false' || true; } | while IFS= read -r kv; do
                [[ -z "$kv" ]] && continue
                key="$(echo "$kv" | sed 's/"\([^"]*\)".*/\1/')"
                val="$(echo "$kv" | sed 's/"[^"]*":\s*//' | sed 's/^"//;s/"$//')"
                echo "${key}: ${val}"
            done
            echo "---"
        done
    fi
} > "$MEM_FILE" 2>/dev/null
set -o pipefail

# Count memories
count=0
if command -v jq &>/dev/null; then
    count="$(echo "$MNEMO_RESPONSE" | jq 'length' 2>/dev/null || echo 0)"
else
    count="$(echo "$MNEMO_RESPONSE" | { grep -o '"id"' || true; } | wc -l | tr -d ' ')"
fi

# Register session — uses session_id read from hook stdin (see top of file).
# WORK_DIR is persisted server-side here; subsequent save calls reference it
# via session_id rather than reading a (collidable) /tmp file.
mnemo_register_session "$SESSION_ID" "claude-code" "$WORK_DIR" "" 2>/dev/null || true

# Escape path for JSON
escaped_path="$(echo "$MEM_FILE" | sed 's/\\/\\\\/g')"

# First-session onboarding: detect zero memories
if [[ "$count" == "0" ]]; then
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Welcome to Mnemo. This is a fresh start — no memories yet. Help the user create their first Foundation memories through natural conversation. Ask them to tell you about themselves: who they are, what they build, what tools they use, and what matters to them. Listen, then save each piece as a Foundation/Initialization memory with an appropriate scope. Keep it conversational — not a checklist. Use save-memory.sh with --working-dir and --session-id for each one. When done, let them know they can always say remember this to save something new, or /mnemo:help for a quick reference."}}'
else
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Mnemo loaded %s memories. Read them now: %s"}}' "$count" "$escaped_path"
fi
