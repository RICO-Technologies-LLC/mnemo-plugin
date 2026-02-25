Uninstall Mnemo and clean up all configuration.

**Run this command:**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/setup/uninstall.sh"
```

Then restart Claude Code. This removes your API config, plugin registrations, and auto-approve permissions from `~/.claude/settings.json`.

Your memories are **not deleted** — they remain on the server. If you reinstall later, they'll still be there.
