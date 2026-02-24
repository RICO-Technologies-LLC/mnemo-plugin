# Mnemo

Persistent memory system for Claude Code. Automatically loads memories at session start, prompts to save at session end, before context compression, and when plans are accepted.

Cross-platform: works on Windows (Git Bash), macOS, and Linux.

## Requirements

- **Claude Code** (latest version)
- **bash** (Git Bash on Windows, native on macOS/Linux)
- **curl** (included with Git Bash, native on macOS/Linux)
- **jq** (optional, recommended — falls back to grep/sed parsing)

## Installation

### From GitHub Marketplace (recommended)

1. Add the marketplace:
   ```
   /plugin marketplace add RICO-Technologies-LLC/mnemo-plugin
   ```

2. Install the plugin:
   ```
   /plugin install mnemo@mnemo-plugin
   ```

3. Restart Claude Code.

4. Run setup (first session will prompt you, or run manually):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/setup/setup.sh"
   ```

5. Restart Claude Code again after setup.

### From Local Directory

For local or LAN installations, run the install script directly:

**macOS / Linux:**
```bash
bash setup/install.sh
```

**Windows:**
Double-click `setup/install.bat`

Then run `setup/setup.sh` to create your account and API key.

## Setup

The setup script registers your account, generates an API key, and writes your config file.

**Interactive:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/setup/setup.sh"
```

Choose **Create a new organization** to start fresh, or **Join an existing organization** if your admin has created an account for you.

**With arguments:**
```bash
# New organization
bash "${CLAUDE_PLUGIN_ROOT}/setup/setup.sh" \
  --name "Acme Corp" --email admin@acme.com \
  --first-name John --last-name Doe --password "Pass1234!"

# Join existing
bash "${CLAUDE_PLUGIN_ROOT}/setup/setup.sh" --join \
  --email user@acme.com --password "Pass1234!"
```

Restart Claude Code after setup. Your first session will guide you through creating your initial memories.

## Uninstall

**From marketplace:**
```
/plugin uninstall mnemo@mnemo-plugin
```

**From local install:**
```bash
bash setup/uninstall.sh    # macOS/Linux
```
Or double-click `setup/uninstall.bat` on Windows.

## Configuration

Setup creates `~/.claude/mnemo-config.json` automatically. You can also create it manually:

```json
{
  "apiUrl": "https://mnemo-dffsh5b3b6gadpcu.westus3-01.azurewebsites.net",
  "authMethod": "apikey",
  "apiKey": "your-api-key-here"
}
```

**Environment variable overrides:** `MNEMO_API_URL`, `MNEMO_API_KEY`

## What It Does

| When | What Happens |
|------|-------------|
| **Session starts** | Your memories load automatically via API (Foundation + directory-matched) |
| **Session ends** | Claude is prompted to save any decisions, issues, or notes before exiting |
| **Context compresses** | Claude saves a "Session Continuity" memory so nothing is lost |
| **Plan accepted** | Claude saves the accepted plan as a Decision memory |

## Commands

- `/mnemo:load-memories` — Manually reload memories mid-session (e.g., after switching context)

## Skill

- `/mnemo:memory-system` — Full documentation on how to store, retrieve, search, link, and manage memories

## Auto-Updates

When installed from the GitHub marketplace, the plugin updates automatically when new versions are pushed.
