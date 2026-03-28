#!/usr/bin/env bash
# plan-accepted-check.sh — PostToolUse hook: prompts to save accepted plans as memories.

CONTEXT='REQUIRED: You just accepted an implementation plan. Save it as a memory so future sessions know the decision and approach.\n\nbash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/save-memory.sh\" \\\n  --tier \"<Operational or Strategic>\" --category \"Decision\" --scope \"<relevant scope>\" \\\n  --topic \"<short name for the plan>\" --content \"<what will be built, key design decisions, chosen approach>\" \\\n  --source \"claude\" --working-dir \"$PWD\" --session-id \"$CLAUDE_SESSION_ID\"\n\nTier: Use Operational (3mo) for most plans. Use Strategic (1yr) only for plans that establish long-lived conventions or architecture. If this plan supersedes a previous decision, add --supersedes <old_memory_id> to link them.\n\nWrite content as a concise summary: DECISION: <what was decided>. APPROACH: <how it will be built>. KEY CHOICES: <notable design decisions>.\n\nSkip ONLY if the plan is trivial (a few-line change with no design decisions). Run in background (run_in_background: true).'

printf '{"decision":"block","reason":"Saving accepted plan as memory...","hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}' "$CONTEXT"
exit 2
