Run the MMRY AI setup flow. This reconfigures the plugin or sets it up for the first time.

## Setup Flow

1. Ask the user: "Are you creating a new organization, or joining one that already exists?"

2. **If creating a new organization**, collect these fields one at a time in natural conversation:
   - Organization name (e.g., their company or team name)
   - First name
   - Last name
   - Email address
   - Password

3. **If joining an existing organization**, collect:
   - Email address (the one their admin created for them)
   - Password

4. **Validate the password before running setup** (8-128 characters, must contain uppercase, lowercase, digit, and special character). If it does not meet requirements, tell them what is missing and ask them to pick a different one.

5. Run the setup script with all arguments pre-filled. Use the Bash tool:

   For new org:
   ```
   bash "${HOME}/.claude/mnemo/setup/mnemo-setup.sh" --name "ORG" --email "EMAIL" --first-name "FIRST" --last-name "LAST" --password "PASS"
   ```

   For joining:
   ```
   bash "${HOME}/.claude/mnemo/setup/mnemo-setup.sh" --join --email "EMAIL" --password "PASS"
   ```

6. **If the script fails**, read the error output and help the user fix it:
   - "Email already registered" — ask if they meant to join instead, or use a different email
   - "Invalid email or password" — ask them to double-check credentials
   - Connection errors — let them know the API may be temporarily unavailable
   Then re-run with corrected values. Do not ask them to run commands manually.

7. **On success**, tell the user: "You're all set. Restart Claude Code and your memories will start loading automatically." Mention they can type /mnemo:help anytime for a quick reference.
