Save a memory to MMRY AI. If the user provided a description after the command, save that. If not, save the most important takeaway from the recent conversation.

## How to Save

1. Determine what to save:
   - If the user wrote something after `/mnemo:save`, save that specific thing.
   - If they just typed `/mnemo:save` with nothing else, review the recent conversation and identify the most important decision, convention, fact, or insight worth persisting.

2. Pick the right metadata based on what's being saved:
   - **Tier**: Foundation (permanent identity/values), Strategic (long-term decisions), Operational (active project knowledge), Tactical (this week's context), Momentary (right now)
   - **Category**: Decision, Convention, Fact, Issue, or Initialization
   - **Scope**: A lowercase keyword describing what area this applies to (e.g., "backend", "frontend", "deployment", "global")
   - **Topic**: A short title (3-8 words)
   - **Content**: The substantive detail. Be specific and actionable, not vague.

3. Run the save script. Use the Bash tool. **Important:** Use the heredoc pattern shown below to prevent bash from expanding `$`, backticks, or other special characters in the content:

   ```
   _mnemo_content=$(cat <<'MNEMO_CONTENT'
   CONTENT
   MNEMO_CONTENT
   )
   bash "${HOME}/.claude/mnemo/hooks-handlers/save-memory.sh" \
     --tier "TIER" \
     --category "CATEGORY" \
     --scope "SCOPE" \
     --topic "TOPIC" \
     --content "$_mnemo_content" \
     --working-dir "$(cat "${TMPDIR:-/tmp}/mnemo-session-dir" 2>/dev/null || echo "$PWD")" \
     --session-id "$CLAUDE_SESSION_ID" \
     --visibility "VISIBILITY" \
     --permission-group-id GROUP_ID
   ```

   `--visibility` and `--permission-group-id` are optional. Visibility defaults to Global. For group-scoped memories, set `--visibility group` and provide the group ID (find it via `list-groups.sh`).

4. Confirm to the user what was saved: the topic, tier, and a one-line summary. Keep it brief.

## Guidelines

- Default to **Operational** tier unless the content clearly fits another tier.
- Default to **Decision** category for choices made, **Convention** for patterns/rules, **Fact** for objective information, **Issue** for problems encountered.
- Keep content under 500 characters. Be dense and specific, not verbose.
- If unsure about scope, use the current project or directory name.
- Do not ask the user to confirm metadata. Just save it. If they want to adjust, they can say so after.
