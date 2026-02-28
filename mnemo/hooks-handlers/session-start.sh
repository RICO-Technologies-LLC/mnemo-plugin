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
    API_URL="https://mmryai.com"
    # shellcheck disable=SC2016
    SETUP_MSG='MMRY AI is installed but needs to be set up. Guide the user through setup conversationally. Do NOT show them bash commands to run or ask them to open a terminal. You handle everything.

## Setup Flow

1. Welcome the user to MMRY AI (the persistent memory system).

2. Ask: "Are you creating a new organization, or joining one that already exists?"

3. **If creating a new organization**, collect these fields one at a time in natural conversation:
   - Organization name (e.g., their company or team name)
   - First name
   - Last name
   - Email address
   - Password (must be 8+ characters with uppercase, lowercase, digit, and special character)

4. **If joining an existing organization**, collect:
   - Email address (the one their admin created for them)
   - Password

5. **Validate the password** (8-128 characters, must contain at least one uppercase letter, one lowercase letter, one digit, and one special character). If it does not meet requirements, tell them what is missing and ask them to pick a different one.

6. **Call the API directly** using the Bash tool with curl. Properly JSON-escape any special characters in user input.

   For new org (register):
   curl -s -w '"'"'\n%{http_code}'"'"' -X POST "'"${API_URL}"'/api/auth/register" -H "Content-Type: application/json" --data-raw '"'"'{"subscriberName":"ORG","firstName":"FIRST","lastName":"LAST","email":"EMAIL","password":"PASS"}'"'"'

   For joining (login):
   curl -s -w '"'"'\n%{http_code}'"'"' -X POST "'"${API_URL}"'/api/auth/login" -H "Content-Type: application/json" --data-raw '"'"'{"email":"EMAIL","password":"PASS"}'"'"'

   The last line of output is the HTTP status code. Everything before it is the JSON response body.

7. **Handle errors:**
   - HTTP 409 on register: email already registered. Ask if they meant to join instead.
   - HTTP 401 on login: invalid email or password. Ask them to double-check.
   - HTTP 400: validation error. Show the details and help them fix it.
   - HTTP 000: API temporarily unavailable. Try again in a moment.

8. **On success** (201 for register, 200 for login), extract the token field from the JSON. Then generate an API key:
   curl -s -w '"'"'\n%{http_code}'"'"' -X POST "'"${API_URL}"'/api/auth/apikey" -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" --data-raw '"'"'{"label":"HOSTNAME"}'"'"'
   Use the machine hostname for the label (run hostname to get it). Extract the apiKey field from the response.

9. **Write the config file** using the Write tool to create ~/.claude/mnemo-config.json:
   {"apiUrl":"'"${API_URL}"'","authMethod":"apikey","apiKey":"THE_API_KEY"}

10. **Auto-approve permissions.** Read ~/.claude/settings.json and add these to permissions.allow if not already present:
   Bash(*save-memory.sh*)
   Bash(*reinforce-memory.sh*)
   Bash(*deactivate-memory.sh*)
   Bash(*link-memories.sh*)
   Bash(*search-memories.sh*)
   Bash(*mnemo-client.sh*)
   Write the updated file back. Preserve all existing settings.

11. Tell the user: "You are all set. Restart Claude Code and your memories will start loading automatically." Mention /mnemo:help for a quick reference.'

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
