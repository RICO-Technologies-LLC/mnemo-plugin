Submit feedback (bug report or feature request) to the MMRY AI team.

## How to Submit Feedback

1. Ask the user what type of feedback this is:
   - **Bug** - something is broken or not working as expected
   - **Feature** - a new capability or improvement they would like

2. Ask for a short title (3-10 words) describing the feedback.

3. Ask for a description:
   - For bugs: What happened? What did you expect to happen?
   - For features: What would you like and why?

4. If the feedback type is **Bug**, ask for reproduction steps:
   - What were you doing when it happened?
   - Can you reproduce it?
   - Collect step-by-step instructions if possible.

5. Ask which component this relates to (optional):
   - Examples: "plugin", "api", "memory loading", "setup", "search"
   - If the user is unsure, skip this.

6. Auto-collect environment information using the Bash tool:

   ```
   echo "OS: $(uname -s) $(uname -r) | Shell: $SHELL | Bash: ${BASH_VERSION:-unknown}"
   ```

7. Submit the feedback using the Bash tool:

   ```
   bash "${HOME}/.claude/mnemo/hooks-handlers/submit-feedback.sh" \
     --type "TYPE" \
     --title "TITLE" \
     --description "DESCRIPTION" \
     --repro-steps "REPRO_STEPS" \
     --component "COMPONENT" \
     --environment "ENVIRONMENT"
   ```

   Omit `--repro-steps` for feature requests. Omit `--component` if not provided.

8. Confirm to the user that their feedback was submitted. Thank them.

## Guidelines

- Be conversational. Ask one or two questions at a time, not all at once.
- For bugs, always ask for repro steps. For features, skip repro steps.
- Keep the description focused and actionable.
- Always auto-collect environment - do not ask the user for it.
- If the user seems frustrated about a bug, acknowledge it before collecting details.
