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

3. Restart Claude Code. Claude will guide you through setup automatically.

4. Restart Claude Code again after setup completes.

### From Local Directory

For local or LAN installations, run the install script directly:

**macOS / Linux:**
```bash
bash setup/install.sh
```

**Windows:**
Double-click `setup/install.bat`

Then run `setup/mnemo-setup.sh` to create your account and API key.

## Setup

When you start Claude Code with the plugin installed but not configured, setup runs automatically. It opens your browser so you can log in or create an account on mmryai.com, then configures everything.

You can also run `/mnemo:setup` at any time to reconfigure or if the automatic prompt didn't trigger.

Restart Claude Code after setup completes.

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
  "apiUrl": "https://mmryai.com",
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

- `/mnemo:save` — Save a memory (or just say "remember this")
- `/mnemo:remember` — Same as save
- `/mnemo:setup` — Run or re-run the account setup flow
- `/mnemo:load-memories` — Manually reload memories mid-session (e.g., after switching context)

## Skill

- `/mnemo:memory-system` — Full documentation on how to store, retrieve, search, link, and manage memories

## Auto-Updates

When installed from the GitHub marketplace, the plugin updates automatically when new versions are pushed.
