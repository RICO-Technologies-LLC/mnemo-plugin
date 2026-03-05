#!/usr/bin/env bash
# mnemo-setup.sh — Interactive Mnemo plugin setup
# Two modes:
#   Register: Creates a new organization (subscriber) and admin account
#   Join:     Joins an existing organization via browser authorization
#
# Usage:
#   bash mnemo-setup.sh
#   bash mnemo-setup.sh --name "Acme Corp" --email admin@acme.com --first-name John --last-name Doe --password "Pass1234!"
#   bash mnemo-setup.sh --join
#   bash mnemo-setup.sh --join --email user@acme.com --password "Pass1234!"
#   bash mnemo-setup.sh --api-url http://localhost:5291

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Defaults
API_URL="https://mmryai.com"
MODE=""  # "register" or "join"
SUBSCRIBER_NAME=""
EMAIL=""
FIRST_NAME=""
LAST_NAME=""
PASSWORD=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --join)        MODE="join"; shift ;;
        --name)        SUBSCRIBER_NAME="$2"; shift 2 ;;
        --email)       EMAIL="$2"; shift 2 ;;
        --first-name)  FIRST_NAME="$2"; shift 2 ;;
        --last-name)   LAST_NAME="$2"; shift 2 ;;
        --password)    PASSWORD="$2"; shift 2 ;;
        --api-url)     API_URL="$2"; shift 2 ;;
        --help|-h)
            echo "Usage:"
            echo "  Register new org:  bash mnemo-setup.sh [--name NAME] [--email EMAIL] [--first-name F] [--last-name L] [--password PASS]"
            echo "  Join existing org: bash mnemo-setup.sh --join"
            echo "  Join (CI/automation): bash mnemo-setup.sh --join --email EMAIL --password PASS"
            echo "  Options:           [--api-url URL]"
            exit 0 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# Check dependencies
if ! command -v curl &>/dev/null; then
    echo "Error: curl is required. Install it and try again."
    exit 1
fi

HAS_JQ=false
if command -v jq &>/dev/null; then
    HAS_JQ=true
fi

# Helper: extract JSON string value (jq or regex fallback)
json_value() {
    local json="$1" key="$2"
    if $HAS_JQ; then
        echo "$json" | jq -r ".${key} // empty"
    else
        echo "$json" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"${key}\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//' | head -1
    fi
}

# Helper: extract JSON numeric value (jq or regex fallback)
json_number() {
    local json="$1" key="$2"
    if $HAS_JQ; then
        echo "$json" | jq -r ".${key} // empty"
    else
        echo "$json" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[0-9]*" | grep -o '[0-9]*$' | head -1
    fi
}

# Helper: escape a string for safe JSON embedding (handles \, ", newlines)
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"   # \ → \\
    s="${s//\"/\\\"}"   # " → \"
    s="${s//$'\n'/\\n}"  # newline → \n
    s="${s//$'\r'/}"     # strip CR
    printf '%s' "$s"
}

# Helper: open a URL in the user's default browser
open_browser() {
    local url="$1"
    case "$(uname -s)" in
        Darwin*)              open "$url" 2>/dev/null ;;
        Linux*)               xdg-open "$url" 2>/dev/null ;;
        MINGW*|MSYS*|CYGWIN*) cmd.exe /c start "" "$url" 2>/dev/null ;;
    esac
    # Always print the URL as fallback (browser open may fail silently)
    if [[ $? -ne 0 ]]; then
        echo "  Open this URL in your browser: $url"
    fi
}

echo ""
echo "=== Mnemo Setup ==="
echo ""

# Interactive mode selection if not specified
if [[ -z "$MODE" ]]; then
    if [[ -n "$SUBSCRIBER_NAME" ]]; then
        MODE="register"
    else
        echo "How would you like to set up Mnemo?"
        echo "  1) Create a new organization"
        echo "  2) Join an existing organization"
        echo ""
        printf "Choice (1 or 2): "
        read -r CHOICE
        case "$CHOICE" in
            1) MODE="register" ;;
            2) MODE="join" ;;
            *) echo "Error: Invalid choice. Enter 1 or 2."; exit 1 ;;
        esac
        echo ""
    fi
fi

# --- JOIN MODE ---
if [[ "$MODE" == "join" ]]; then

    if [[ -n "$EMAIL" && -n "$PASSWORD" ]]; then
        # --- Credential fallback (CI/automation) ---
        echo "Joining an existing organization..."
        echo ""

        echo "Logging in..."
        LOGIN_BODY="{\"email\":\"$(json_escape "$EMAIL")\",\"password\":\"$(json_escape "$PASSWORD")\"}"

        LOGIN_TMP="$(mktemp)"
        LOGIN_CODE=$(curl -s -o "$LOGIN_TMP" -w '%{http_code}' \
            --connect-timeout 10 --max-time 25 \
            -X POST "${API_URL}/api/auth/login" \
            -H "Content-Type: application/json" \
            -d "$LOGIN_BODY")

        LOGIN_RESP="$(cat "$LOGIN_TMP")"
        rm -f "$LOGIN_TMP"

        if [[ "$LOGIN_CODE" == "401" ]]; then
            echo "Error: Invalid email or password."
            exit 1
        elif [[ "$LOGIN_CODE" != "200" ]]; then
            echo "Error: Login failed (HTTP ${LOGIN_CODE})."
            echo "$LOGIN_RESP"
            exit 1
        fi

        echo "  Logged in successfully."
        TOKEN="$(json_value "$LOGIN_RESP" "token")"

        if [[ -z "$TOKEN" ]]; then
            echo "Error: No token in response."
            exit 1
        fi

        echo "Generating API key..."
        MACHINE_LABEL="$(hostname 2>/dev/null || echo "unknown")"
        KEY_BODY="{\"label\":\"${MACHINE_LABEL}\"}"

        KEY_TMP="$(mktemp)"
        KEY_CODE=$(curl -s -o "$KEY_TMP" -w '%{http_code}' \
            --connect-timeout 10 --max-time 25 \
            -X POST "${API_URL}/api/auth/apikey" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$KEY_BODY")

        KEY_RESP="$(cat "$KEY_TMP")"
        rm -f "$KEY_TMP"

        if [[ "$KEY_CODE" != "201" ]]; then
            echo "Error: API key generation failed (HTTP ${KEY_CODE})."
            echo "$KEY_RESP"
            exit 1
        fi

        API_KEY="$(json_value "$KEY_RESP" "apiKey")"
        if [[ -z "$API_KEY" ]]; then
            echo "Error: No API key in response."
            exit 1
        fi
        echo "  API key generated."

    else
        # --- Device authorization flow (default interactive) ---
        if [[ -n "$EMAIL" || -n "$PASSWORD" ]]; then
            echo "Note: Both --email and --password are required for credential mode. Using browser authorization."
            echo ""
        fi

        echo "Joining an existing organization..."
        echo ""

        # Step 1: Request device code
        echo "Requesting authorization..."
        DEVICE_TMP="$(mktemp)"
        DEVICE_CODE_HTTP=$(curl -s -o "$DEVICE_TMP" -w '%{http_code}' \
            --connect-timeout 10 --max-time 25 \
            -X POST "${API_URL}/api/auth/device")

        DEVICE_RESP="$(cat "$DEVICE_TMP")"
        rm -f "$DEVICE_TMP"

        if [[ "$DEVICE_CODE_HTTP" != "200" ]]; then
            echo "Error: Could not start device authorization (HTTP ${DEVICE_CODE_HTTP})."
            echo "$DEVICE_RESP"
            exit 1
        fi

        DEVICE_CODE="$(json_value "$DEVICE_RESP" "deviceCode")"
        VERIFICATION_URL="$(json_value "$DEVICE_RESP" "verificationUrl")"
        EXPIRES_IN="$(json_number "$DEVICE_RESP" "expiresIn")"
        POLL_INTERVAL="$(json_number "$DEVICE_RESP" "interval")"

        # Defaults if server doesn't return them
        EXPIRES_IN="${EXPIRES_IN:-600}"
        POLL_INTERVAL="${POLL_INTERVAL:-2}"

        if [[ -z "$DEVICE_CODE" || -z "$VERIFICATION_URL" ]]; then
            echo "Error: Invalid device authorization response."
            exit 1
        fi

        # Step 2: Open browser
        AUTHORIZE_URL="${VERIFICATION_URL}?code=${DEVICE_CODE}"
        echo ""
        echo "Opening your browser to authorize this device..."
        echo "  ${AUTHORIZE_URL}"
        echo ""
        open_browser "$AUTHORIZE_URL"
        echo "Waiting for authorization (expires in $((EXPIRES_IN / 60)) minutes)..."

        # Step 3: Poll for authorization
        ELAPSED=0
        while (( ELAPSED < EXPIRES_IN )); do
            sleep "$POLL_INTERVAL"
            ELAPSED=$(( ELAPSED + POLL_INTERVAL ))

            STATUS_TMP="$(mktemp)"
            STATUS_CODE=$(curl -s -o "$STATUS_TMP" -w '%{http_code}' \
                --connect-timeout 10 --max-time 15 \
                "${API_URL}/api/auth/device/${DEVICE_CODE}/status")

            STATUS_RESP="$(cat "$STATUS_TMP")"
            rm -f "$STATUS_TMP"

            if [[ "$STATUS_CODE" == "429" ]]; then
                # Rate limited - back off
                sleep "$POLL_INTERVAL"
                ELAPSED=$(( ELAPSED + POLL_INTERVAL ))
                continue
            fi

            if [[ "$STATUS_CODE" != "200" ]]; then
                echo "Error: Status check failed (HTTP ${STATUS_CODE})."
                echo "$STATUS_RESP"
                exit 1
            fi

            DEVICE_STATUS="$(json_value "$STATUS_RESP" "status")"

            if [[ "$DEVICE_STATUS" == "authorized" ]]; then
                API_KEY="$(json_value "$STATUS_RESP" "apiKey")"
                if [[ -z "$API_KEY" ]]; then
                    echo "Error: Authorization succeeded but no API key returned."
                    exit 1
                fi
                echo "  Authorized!"
                break
            elif [[ "$DEVICE_STATUS" == "expired" ]]; then
                echo "Error: Device code expired. Please run setup again."
                exit 1
            fi
            # status == "pending" - keep polling
        done

        if (( ELAPSED >= EXPIRES_IN )) && [[ -z "${API_KEY:-}" ]]; then
            echo "Error: Authorization timed out. Please run setup again."
            exit 1
        fi
    fi

# --- REGISTER MODE ---
else
    echo "Creating a new organization..."
    echo ""

    # Prompt for missing values
    if [[ -z "$SUBSCRIBER_NAME" ]]; then
        printf "Organization name: "
        read -r SUBSCRIBER_NAME
    fi
    if [[ -z "$SUBSCRIBER_NAME" ]]; then
        echo "Error: Organization name is required."
        exit 1
    fi

    if [[ -z "$FIRST_NAME" ]]; then
        printf "First name: "
        read -r FIRST_NAME
    fi
    if [[ -z "$FIRST_NAME" ]]; then
        echo "Error: First name is required."
        exit 1
    fi

    if [[ -z "$LAST_NAME" ]]; then
        printf "Last name: "
        read -r LAST_NAME
    fi
    if [[ -z "$LAST_NAME" ]]; then
        echo "Error: Last name is required."
        exit 1
    fi

    if [[ -z "$EMAIL" ]]; then
        printf "Email: "
        read -r EMAIL
    fi
    if [[ -z "$EMAIL" ]]; then
        echo "Error: Email is required."
        exit 1
    fi

    if [[ -z "$PASSWORD" ]]; then
        printf "Password (min 8 chars, upper+lower+digit+special): "
        if [[ -t 0 ]]; then
            read -rs PASSWORD
            echo ""
        else
            read -r PASSWORD
        fi
    fi
    if [[ -z "$PASSWORD" ]]; then
        echo "Error: Password is required."
        exit 1
    fi

    echo ""
    echo "Registering with ${API_URL}..."

    REGISTER_BODY="{\"subscriberName\":\"$(json_escape "$SUBSCRIBER_NAME")\",\"email\":\"$(json_escape "$EMAIL")\",\"password\":\"$(json_escape "$PASSWORD")\",\"firstName\":\"$(json_escape "$FIRST_NAME")\",\"lastName\":\"$(json_escape "$LAST_NAME")\"}"

    REG_TMP="$(mktemp)"
    REG_CODE=$(curl -s -o "$REG_TMP" -w '%{http_code}' \
        --connect-timeout 10 --max-time 25 \
        -X POST "${API_URL}/api/auth/register" \
        -H "Content-Type: application/json" \
        -d "$REGISTER_BODY")

    REG_RESP="$(cat "$REG_TMP")"
    rm -f "$REG_TMP"

    if [[ "$REG_CODE" == "409" ]]; then
        echo "Error: Email '${EMAIL}' is already registered."
        exit 1
    elif [[ "$REG_CODE" == "400" ]]; then
        echo "Error: Validation failed."
        echo "$REG_RESP"
        exit 1
    elif [[ "$REG_CODE" != "201" ]]; then
        echo "Error: Registration failed (HTTP ${REG_CODE})."
        echo "$REG_RESP"
        exit 1
    fi

    echo "  Registered successfully."
    TOKEN="$(json_value "$REG_RESP" "token")"

    if [[ -z "$TOKEN" ]]; then
        echo "Error: No token in response."
        exit 1
    fi

    # Generate API key
    echo "Generating API key..."
    MACHINE_LABEL="$(hostname 2>/dev/null || echo "unknown")"
    KEY_BODY="{\"label\":\"${MACHINE_LABEL}\"}"

    KEY_TMP="$(mktemp)"
    KEY_CODE=$(curl -s -o "$KEY_TMP" -w '%{http_code}' \
        --connect-timeout 10 --max-time 25 \
        -X POST "${API_URL}/api/auth/apikey" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$KEY_BODY")

    KEY_RESP="$(cat "$KEY_TMP")"
    rm -f "$KEY_TMP"

    if [[ "$KEY_CODE" != "201" ]]; then
        echo "Error: API key generation failed (HTTP ${KEY_CODE})."
        echo "$KEY_RESP"
        exit 1
    fi

    API_KEY="$(json_value "$KEY_RESP" "apiKey")"
    if [[ -z "$API_KEY" ]]; then
        echo "Error: No API key in response."
        exit 1
    fi
    echo "  API key generated."
fi

# --- Common: Write config and configure plugin ---

# Write config file
CONFIG_DIR="${HOME}/.claude"
CONFIG_FILE="${CONFIG_DIR}/mnemo-config.json"

mkdir -p "$CONFIG_DIR"

if $HAS_JQ; then
    jq -n --arg url "$API_URL" --arg key "$API_KEY" '{
        apiUrl: $url,
        authMethod: "apikey",
        apiKey: $key
    }' > "$CONFIG_FILE"
else
    cat > "$CONFIG_FILE" << EOF
{
  "apiUrl": "${API_URL}",
  "authMethod": "apikey",
  "apiKey": "${API_KEY}"
}
EOF
fi

echo "  Config written to ${CONFIG_FILE}"

# Auto-approve Mnemo scripts in Claude Code settings
SETTINGS_FILE="${HOME}/.claude/settings.json"
MNEMO_PERMISSIONS=(
    "Bash(*save-memory.sh*)"
    "Bash(*reinforce-memory.sh*)"
    "Bash(*deactivate-memory.sh*)"
    "Bash(*link-memories.sh*)"
    "Bash(*search-memories.sh*)"
    "Bash(*list-groups.sh*)"
    "Bash(*submit-feedback.sh*)"
    "Bash(*mnemo-client.sh*)"
)

if $HAS_JQ; then
    # Create settings file if it doesn't exist
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo '{}' > "$SETTINGS_FILE"
    fi

    # Build jq filter to add permissions
    JQ_FILTER='.permissions //= {} | .permissions.allow //= []'
    for perm in "${MNEMO_PERMISSIONS[@]}"; do
        JQ_FILTER+=" | if (.permissions.allow | index(\"${perm}\")) then . else .permissions.allow += [\"${perm}\"] end"
    done

    jq "$JQ_FILTER" "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" \
        && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    echo "  Script permissions configured."
else
    # Non-jq fallback: check if permissions already present, add if missing
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        cat > "$SETTINGS_FILE" << 'SETTINGSEOF'
{
  "permissions": {
    "allow": [
      "Bash(*save-memory.sh*)",
      "Bash(*reinforce-memory.sh*)",
      "Bash(*deactivate-memory.sh*)",
      "Bash(*link-memories.sh*)",
      "Bash(*search-memories.sh*)",
      "Bash(*list-groups.sh*)",
      "Bash(*submit-feedback.sh*)",
      "Bash(*mnemo-client.sh*)"
    ]
  }
}
SETTINGSEOF
        echo "  Script permissions configured."
    elif grep -q "save-memory.sh" "$SETTINGS_FILE" 2>/dev/null; then
        echo "  Script permissions already configured."
    else
        # settings.json exists but needs permissions — try Python, then manual fallback
        PERMS_ADDED=false
        PY_CMD=""
        if command -v python3 &>/dev/null; then
            PY_CMD="python3"
        elif command -v python &>/dev/null; then
            PY_CMD="python"
        fi

        if [[ -n "$PY_CMD" ]]; then
            "$PY_CMD" - "$SETTINGS_FILE" << 'PYEOF' && PERMS_ADDED=true
import json, sys
sf = sys.argv[1]
perms = [
    "Bash(*save-memory.sh*)",
    "Bash(*reinforce-memory.sh*)",
    "Bash(*deactivate-memory.sh*)",
    "Bash(*link-memories.sh*)",
    "Bash(*search-memories.sh*)",
    "Bash(*list-groups.sh*)",
    "Bash(*submit-feedback.sh*)",
    "Bash(*mnemo-client.sh*)"
]
with open(sf) as f:
    data = json.load(f)
data.setdefault("permissions", {}).setdefault("allow", [])
for p in perms:
    if p not in data["permissions"]["allow"]:
        data["permissions"]["allow"].append(p)
with open(sf, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
        fi

        if $PERMS_ADDED; then
            echo "  Script permissions configured."
        else
            echo "  Note: Could not auto-configure permissions (jq and python not found)."
            echo "  Add these to ${SETTINGS_FILE} under permissions.allow:"
            for perm in "${MNEMO_PERMISSIONS[@]}"; do
                echo "    \"${perm}\""
            done
        fi
    fi
fi

# Install plugin (skip for marketplace/stable installs — already handled by Claude Code)
SCRIPT_DIR_RESOLVED="$(cd "$SCRIPT_DIR" && pwd)"
if [[ "$SCRIPT_DIR_RESOLVED" == *"/.claude/plugins/cache/"* || "$SCRIPT_DIR_RESOLVED" == *"/.claude/mnemo/"* ]]; then
    echo "  Plugin already installed via marketplace."
else
    echo "Installing plugin..."
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            # Windows: delegate to PowerShell script (no bash dependency for install)
            if [[ -f "${SCRIPT_DIR}/install.ps1" ]]; then
                powershell.exe -ExecutionPolicy Bypass -File "${SCRIPT_DIR}/install.ps1" 2>/dev/null
                echo "  Plugin installed."
            else
                echo "  Error: install.ps1 not found."
                exit 1
            fi
            ;;
        *)
            # macOS/Linux: use bash install script
            if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
                bash "${SCRIPT_DIR}/install.sh" 2>/dev/null
                echo "  Plugin installed."
            else
                echo "  Error: install.sh not found."
                exit 1
            fi
            ;;
    esac

    # Clear stale cache (local installs only)
    CACHE_DIR="${HOME}/.claude/plugins/cache/internal-plugins/mnemo"
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        echo "  Plugin cache cleared."
    fi
fi

echo ""
echo "=== You're all set ==="
echo ""
echo "Mnemo will remember your decisions, conventions, and context across every"
echo "session. You don't need to do anything special — it works in the background."
echo ""
echo "Restart Claude Code to get started."
echo ""
if [[ "$MODE" == "register" ]]; then
    echo "On your first session, Claude will help you create your initial memories."
    echo "Just tell it about your team, your tools, and how you like to work."
    echo ""
fi
echo "Anytime you need help, type: /mnemo:help"
