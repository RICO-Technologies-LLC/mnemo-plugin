#!/usr/bin/env bash
# session-init.sh — SessionStart hook entry point.
# Discovers the plugin root, copies handler scripts to ~/.claude/mmry/,
# then delegates to session-start.sh for memory loading.
#
# Extracted from hooks.json inline command to avoid bash -c quoting issues
# on Windows where cmd.exe misinterprets && and || inside single quotes.

set -euo pipefail

# Discover plugin root: prefer CLAUDE_PLUGIN_ROOT, fall back to filesystem search
P="${CLAUDE_PLUGIN_ROOT:-}"
P="${P//\\//}"  # Normalize backslashes to forward slashes (Windows)

if [[ -z "$P" ]] || [[ ! -d "$P/hooks-handlers" ]]; then
    P="$(find "${HOME}/.claude/plugins" -path "*/mmry/hooks-handlers" -type d 2>/dev/null | head -1 | sed 's|/hooks-handlers$||')"
fi

if [[ -z "$P" ]]; then
    echo "MMRY AI: Could not locate plugin root. Run /mmry:setup"
    exit 0
fi

# Clean old hooks dir, create target directories
rm -rf "${HOME}/.claude/mmry/hooks" 2>/dev/null
mkdir -p "${HOME}/.claude/mmry/hooks-handlers" "${HOME}/.claude/mmry/setup"

# Copy current handler and setup scripts (all platforms)
cp "$P"/hooks-handlers/*.sh "${HOME}/.claude/mmry/hooks-handlers/"
cp "$P"/setup/*.sh "${HOME}/.claude/mmry/setup/"
cp "$P"/setup/*.bat "${HOME}/.claude/mmry/setup/" 2>/dev/null || true
cp "$P"/setup/*.ps1 "${HOME}/.claude/mmry/setup/" 2>/dev/null || true

# Delegate to the main session-start logic
bash "$P/hooks-handlers/session-start.sh"
