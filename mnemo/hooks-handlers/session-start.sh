#!/usr/bin/env bash
# SessionStart hook: loads memories from Mnemo API via curl.
# Outputs hook JSON with path to temp file containing loaded memories.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
source "${PLUGIN_ROOT}/hooks-handlers/mnemo-client.sh"

WORK_DIR="$PWD"

# Check if config is loaded — guide unconfigured users to run setup
if [[ -z "${MNEMO_API_KEY:-}" ]]; then
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Mnemo is installed but not configured yet. Run setup to create your account and API key:\\n\\nbash \\\"${CLAUDE_PLUGIN_ROOT}/setup/mnemo-setup.sh\\\"\\n\\nThen restart Claude Code."}}'
    exit 0
fi

MEM_FILE="${MNEMO_TMPDIR}/mnemo-memories.md"

# Load startup memories
if ! mnemo_get_startup_memories "$WORK_DIR"; then
    if [[ "${MNEMO_HTTP_CODE:-}" == "403" ]]; then
        printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Mnemo trial has expired. Inform the user that their free trial has ended and they need to upgrade to continue using memory features."}}'
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

# Register session
session_id="${CLAUDE_SESSION_ID:-unknown}"
mnemo_register_session "$session_id" "claude-code" "$WORK_DIR" "" 2>/dev/null || true

# Escape path for JSON
escaped_path="$(echo "$MEM_FILE" | sed 's/\\/\\\\/g')"

# First-session onboarding: detect zero memories
if [[ "$count" == "0" ]]; then
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Welcome to Mnemo. This is a fresh start — no memories yet. Help the user create their first Foundation memories through natural conversation. Ask them to tell you about themselves: who they are, what they build, what tools they use, and what matters to them. Listen, then save each piece as a Foundation/Initialization memory with an appropriate scope. Keep it conversational — not a checklist. Use save-memory.sh with --working-dir and --session-id for each one. When done, let them know they can always say remember this to save something new, or /mnemo:help for a quick reference."}}'
else
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Mnemo loaded %s memories. Read them now: %s"}}' "$count" "$escaped_path"
fi
