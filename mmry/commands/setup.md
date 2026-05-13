Run the MMRY AI setup flow. This configures the plugin or reconfigures it for a new account.

## Setup

Run this command using the Bash tool:

```bash
bash ~/.claude/mnemo/setup/mnemo-setup.sh
```

This opens a browser window where the user can log in or create an account on mmryai.com. Once they authorize, the script writes the config file and permissions automatically.

If the browser does not open, the script prints a URL the user can copy and paste.

After setup completes, tell the user: "You're all set. Restart Claude Code and your memories will start loading automatically. Type /mnemo:help anytime for a quick reference."

If the user does not have an account yet, direct them to https://mmryai.com to sign up first, then run setup again.
