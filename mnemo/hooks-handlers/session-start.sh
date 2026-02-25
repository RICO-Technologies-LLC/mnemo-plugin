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
    SETUP_SCRIPT="${HOME}/.claude/mnemo/setup/mnemo-setup.sh"
    # shellcheck disable=SC2016
    SETUP_MSG='MMRY AI is installed but needs to be set up. Guide the user through setup conversationally. Do NOT show them bash commands to run — you will handle everything.

## Setup Flow

1. Welcome the user to MMRY AI (the persistent memory system).

2. Ask: "Are you creating a new organization, or joining one that already exists?"

3. **If creating a new organization**, collect these fields one at a time in natural conversation:
   - Organization name (e.g., their company or team name)
   - First name
   - Last name
   - Email address
   - Password

4. **If joining an existing organization**, collect:
   - Email address (the one their admin created for them)
   - Password

5. **Validate the password before running setup** (8-128 characters, must contain uppercase, lowercase, digit, and special character). If it does not meet requirements, tell them what is missing and ask them to pick a different one.

6. Run the setup script with all arguments pre-filled. Use the Bash tool:

   For new org:
   ```
   bash "'"${SETUP_SCRIPT}"'" --name "ORG" --email "EMAIL" --first-name "FIRST" --last-name "LAST" --password "PASS"
   ```

   For joining:
   ```
   bash "'"${SETUP_SCRIPT}"'" --join --email "EMAIL" --password "PASS"
   ```

7. **If the script fails**, read the error output and help the user fix it:
   - "Email already registered" — ask if they meant to join instead, or use a different email
   - "Invalid email or password" — ask them to double-check credentials
   - Connection errors — let them know the API may be temporarily unavailable
   Then re-run with corrected values. Do not ask them to run commands manually.

8. **On success**, tell the user: "You are all set. Restart Claude Code and your memories will start loading automatically." Mention they can type /mnemo:help anytime for a quick reference.'

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
