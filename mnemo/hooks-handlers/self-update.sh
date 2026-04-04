#!/usr/bin/env bash
# self-update.sh — Check for plugin updates and apply them automatically.
# Called from session-start.sh before loading memories.
# Returns 0 if no update needed or update succeeded, 1 on error.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_VERSION_FILE="${PLUGIN_ROOT}/.claude-plugin/plugin.json"
MARKETPLACE_URL="https://raw.githubusercontent.com/RICO-Technologies-LLC/mnemo-plugin/master/.claude-plugin/marketplace.json"
REPO_ARCHIVE_URL="https://github.com/RICO-Technologies-LLC/mnemo-plugin/archive/refs/heads/master.tar.gz"

TMPDIR="${TMPDIR:-/tmp}"
UPDATE_MARKER="${TMPDIR}/.mnemo-update-checked"

# Debounce — only check once per hour
if [[ -f "$UPDATE_MARKER" ]]; then
    now=$(date +%s)
    if stat --version &>/dev/null 2>&1; then
        mtime=$(stat -c %Y "$UPDATE_MARKER" 2>/dev/null || echo 0)
    else
        mtime=$(stat -f %m "$UPDATE_MARKER" 2>/dev/null || echo 0)
    fi
    age=$(( now - mtime ))
    if (( age < 3600 )); then
        exit 0
    fi
fi

touch "$UPDATE_MARKER"

# Get local version
local_version=""
if [[ -f "$LOCAL_VERSION_FILE" ]]; then
    if command -v jq &>/dev/null; then
        local_version="$(jq -r '.version // empty' "$LOCAL_VERSION_FILE" 2>/dev/null)"
    else
        local_version="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$LOCAL_VERSION_FILE" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//' | head -1)"
    fi
fi

if [[ -z "$local_version" ]]; then
    # Can't determine local version — skip update check
    exit 0
fi

# Get remote version (with short timeout — don't block session start)
remote_json=""
remote_json="$(curl -s --connect-timeout 5 --max-time 10 "$MARKETPLACE_URL" 2>/dev/null)" || exit 0

remote_version=""
if command -v jq &>/dev/null; then
    remote_version="$(echo "$remote_json" | jq -r '.plugins[0].version // empty' 2>/dev/null)"
else
    remote_version="$(echo "$remote_json" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')"
fi

if [[ -z "$remote_version" ]]; then
    exit 0
fi

# Compare versions — if same, no update needed
if [[ "$local_version" == "$remote_version" ]]; then
    exit 0
fi

# Version mismatch — download and apply update
tmp_archive="$(mktemp "${TMPDIR}/mnemo-update-XXXXXX.tar.gz")"
tmp_extract="$(mktemp -d "${TMPDIR}/mnemo-update-XXXXXX")"

cleanup() {
    rm -rf "$tmp_archive" "$tmp_extract"
}
trap cleanup EXIT

# Download the archive
if ! curl -sL --connect-timeout 10 --max-time 30 -o "$tmp_archive" "$REPO_ARCHIVE_URL" 2>/dev/null; then
    exit 0
fi

# Extract
if ! tar -xzf "$tmp_archive" -C "$tmp_extract" 2>/dev/null; then
    exit 0
fi

# Find the extracted directory (GitHub archives as repo-name-branch/)
extracted_dir="$(find "$tmp_extract" -maxdepth 1 -type d -name 'mnemo-plugin-*' | head -1)"
if [[ -z "$extracted_dir" || ! -d "${extracted_dir}/mnemo" ]]; then
    exit 0
fi

# Copy updated files to the plugin root
# Preserve the plugin root directory but overwrite contents
cp -r "${extracted_dir}/mnemo/"* "${PLUGIN_ROOT}/" 2>/dev/null || exit 0

# Also update the installed copy if it exists at ~/.claude/mnemo/
INSTALLED_DIR="${HOME}/.claude/mnemo"
if [[ -d "$INSTALLED_DIR" && "$PLUGIN_ROOT" != "$INSTALLED_DIR" ]]; then
    cp -r "${extracted_dir}/mnemo/"* "${INSTALLED_DIR}/" 2>/dev/null || true
fi

echo "Mnemo plugin updated: ${local_version} -> ${remote_version}" >&2
exit 0
