#!/usr/bin/env bash
# plan-accepted-check.sh — PostToolUse hook: sends accepted plan context to Mnemo API.

set -euo pipefail

CONTEXT='REQUIRED: You just accepted an implementation plan. Write a summary of the plan and send it to the Mnemo API.\n\nCall the process endpoint:\n\nbash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/process-context.sh\" \\\n  --hook-type \"planAccepted\" \\\n  --context \"<summary of the accepted plan: what will be built, key design decisions, chosen approach>\" \\\n  --working-dir \"$PWD\" \\\n  --session-id \"$CLAUDE_SESSION_ID\"\n\nThe server will decide how to classify and store this. Just provide a thorough summary of the decision.\n\nRun in background (run_in_background: true).'

printf '{"decision":"block","reason":"Saving accepted plan as memory...","systemMessage":"%s"}' "$CONTEXT"
exit 2
