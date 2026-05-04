Save a memory to MMRY AI. If the user provided a description after the command, save that. If not, save the most important takeaway from the recent conversation.

## How to Save

1. Determine what to save:
   - If the user wrote something after `/mnemo:remember`, save that specific thing.
   - If they just typed `/mnemo:remember` with nothing else, review the recent conversation and identify the most important decision, convention, fact, or insight worth persisting.

2. Run the save script. Use the Bash tool. Pass the substantive content as `--context`. Mnemo's server processes the context and decides how to file it. **Important:** Use the heredoc pattern shown below to prevent bash from expanding `$`, backticks, or other special characters in the content:

   ```
   _mnemo_context=$(cat <<'MNEMO_CONTEXT'
   CONTEXT
   MNEMO_CONTEXT
   )
   bash "${HOME}/.claude/mnemo/hooks-handlers/save-memory.sh" \
     --context "$_mnemo_context" \
     --working-dir "$(cat "${TMPDIR:-/tmp}/mnemo-session-dir-${CLAUDE_SESSION_ID:-_}" 2>/dev/null || cat "${TMPDIR:-/tmp}/mnemo-session-dir" 2>/dev/null || echo "$PWD")" \
     --session-id "$CLAUDE_SESSION_ID"
   ```

   Replace `CONTEXT` with the substantive content you want to save. Be specific and actionable, not vague. Include enough surrounding context that the server can file it correctly (e.g., what project or topic it relates to, why it matters).

3. Confirm to the user that the memory was sent for processing. Keep it brief — one sentence. Do **not** announce internal classification details (the server decides those).

## Guidelines

- Keep the context dense and specific. Aim for under 500 characters of substantive content unless the situation genuinely needs more.
- If the user pushes back on what was saved, ask them what they'd like changed and save a follow-up memory with the correction. Do not try to override the server's decision from the client.
- Do not ask the user to confirm before saving. Just save it.
