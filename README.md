# Mnemo Plugin for Claude Code

Persistent memory system that gives Claude Code long-term recall across sessions.

- **Session start**: Automatically loads your memories
- **Session end**: Prompts to save decisions, issues, and conventions
- **Context compression**: Saves continuity notes so nothing is lost
- **Plan accepted**: Saves accepted plans as decision records

## Quick Start

### 1. Add the marketplace

```
/plugin marketplace add RICO-Technologies-LLC/mnemo-plugin
```

### 2. Install the plugin

```
/plugin install mnemo@mnemo-plugin
```

### 3. Restart Claude Code

### 4. Run setup

On first session, you'll be prompted to configure your account. Or run manually:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/setup/setup.sh"
```

Choose **Create a new organization** to start fresh, or **Join an existing organization** if your admin has created an account for you.

### 5. Restart Claude Code again

Your memories will load automatically from now on.

## Requirements

- **Claude Code** (latest version)
- **bash** (Git Bash on Windows, native on macOS/Linux)
- **curl** (included with Git Bash, native on macOS/Linux)
- **jq** (optional but recommended)

## Documentation

See the [plugin README](mnemo/README.md) for full documentation on configuration, commands, and the memory skill.

## License

MIT
