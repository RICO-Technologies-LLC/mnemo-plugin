#!/usr/bin/env bash
# mnemo-client.sh — Mnemo REST API client library (bash+curl)
# Source this file to access all Mnemo API functions.
# Version: 2.0.0

set -euo pipefail

# ============================================================================
# 1. CONFIG LOADING
# ============================================================================

MNEMO_API_URL="${MNEMO_API_URL:-}"
MNEMO_API_KEY="${MNEMO_API_KEY:-}"
MNEMO_AUTH_METHOD="${MNEMO_AUTH_METHOD:-}"

# Temp directory — cross-platform
MNEMO_TMPDIR="${TMPDIR:-/tmp}"

# HTTP response globals
MNEMO_HTTP_CODE=""
MNEMO_RESPONSE=""

# Default API URL
_MNEMO_DEFAULT_URL="https://mmryai.com"

_mnemo_urlencode() {
    # URL-encode a string using sed (cross-platform, no curl trick)
    local str="$1"
    printf '%s' "$str" | sed \
        -e 's|%|%25|g' \
        -e 's| |%20|g' \
        -e 's|:|%3A|g' \
        -e 's|\\|%5C|g' \
        -e 's|#|%23|g' \
        -e 's|?|%3F|g' \
        -e 's|&|%26|g' \
        -e 's|=|%3D|g' \
        -e 's|+|%2B|g' \
        -e 's|@|%40|g'
}

_mnemo_parse_json_value() {
    # Parse a value from flat JSON using grep/sed (no jq dependency)
    # Usage: _mnemo_parse_json_value "$json" "key"
    local json="$1" key="$2"
    echo "$json" | { grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" || true; } | sed "s/\"${key}\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//' | head -1
}

mnemo_load_config() {
    # Discovery order: $MNEMO_CONFIG_FILE → plugin root → ~/.claude/
    local config_file=""
    local plugin_root="${CLAUDE_PLUGIN_ROOT:-}"

    if [[ -n "${MNEMO_CONFIG_FILE:-}" && -f "${MNEMO_CONFIG_FILE}" ]]; then
        config_file="$MNEMO_CONFIG_FILE"
    elif [[ -n "$plugin_root" && -f "${plugin_root}/mnemo-config.json" ]]; then
        config_file="${plugin_root}/mnemo-config.json"
    elif [[ -f "${HOME}/.claude/mnemo-config.json" ]]; then
        config_file="${HOME}/.claude/mnemo-config.json"
    fi

    if [[ -n "$config_file" ]]; then
        local content
        content="$(cat "$config_file")"

        # Parse with jq if available, otherwise regex fallback
        if command -v jq &>/dev/null; then
            local val
            val="$(echo "$content" | jq -r '.apiUrl // empty')"
            [[ -z "$MNEMO_API_URL" && -n "$val" ]] && MNEMO_API_URL="$val" || true
            val="$(echo "$content" | jq -r '.authMethod // empty')"
            [[ -z "$MNEMO_AUTH_METHOD" && -n "$val" ]] && MNEMO_AUTH_METHOD="$val" || true
            val="$(echo "$content" | jq -r '.apiKey // empty')"
            [[ -z "$MNEMO_API_KEY" && -n "$val" ]] && MNEMO_API_KEY="$val" || true
        else
            local val
            val="$(_mnemo_parse_json_value "$content" "apiUrl")"
            [[ -z "$MNEMO_API_URL" && -n "$val" ]] && MNEMO_API_URL="$val" || true
            val="$(_mnemo_parse_json_value "$content" "authMethod")"
            [[ -z "$MNEMO_AUTH_METHOD" && -n "$val" ]] && MNEMO_AUTH_METHOD="$val" || true
            val="$(_mnemo_parse_json_value "$content" "apiKey")"
            [[ -z "$MNEMO_API_KEY" && -n "$val" ]] && MNEMO_API_KEY="$val" || true
        fi
    fi

    # Apply defaults
    MNEMO_API_URL="${MNEMO_API_URL:-$_MNEMO_DEFAULT_URL}"

    # Auto-detect auth method if not set
    if [[ -z "$MNEMO_AUTH_METHOD" && -n "$MNEMO_API_KEY" ]]; then
        MNEMO_AUTH_METHOD="apikey"
    fi
}

# ============================================================================
# 2. AUTHENTICATION
# ============================================================================

_mnemo_get_auth_header() {
    if [[ "$MNEMO_AUTH_METHOD" == "apikey" && -n "$MNEMO_API_KEY" ]]; then
        echo "X-Api-Key: ${MNEMO_API_KEY}"
        return 0
    fi

    MNEMO_RESPONSE="No API key configured. Run /mnemo:setup to configure your account."
    return 1
}

# ============================================================================
# 4. CORE HTTP
# ============================================================================

_mnemo_request() {
    # Usage: _mnemo_request METHOD PATH [BODY]
    # Sets MNEMO_HTTP_CODE and MNEMO_RESPONSE globals
    # Returns 0 for 2xx, 1 otherwise
    local method="$1"
    local path="$2"
    local body="${3:-}"

    local auth_header
    auth_header="$(_mnemo_get_auth_header)" || {
        MNEMO_HTTP_CODE="000"
        MNEMO_RESPONSE="Authentication failed"
        return 1
    }

    local tmp_resp
    tmp_resp="$(mktemp "${MNEMO_TMPDIR}/mnemo-resp-XXXXXX")"

    local curl_args=(-s -o "$tmp_resp" -w '%{http_code}'
        --connect-timeout 10 --max-time 25
        -X "$method"
        -H "$auth_header"
        -H "Content-Type: application/json; charset=utf-8")

    local tmp_body=""
    if [[ -n "$body" ]]; then
        tmp_body="$(mktemp "${MNEMO_TMPDIR}/mnemo-body-XXXXXX")"
        printf '%s' "$body" > "$tmp_body"
        curl_args+=(--data-binary "@${tmp_body}")
    fi

    local http_code
    http_code=$(curl "${curl_args[@]}" "${MNEMO_API_URL}${path}") || {
        rm -f "$tmp_resp" "$tmp_body"
        MNEMO_HTTP_CODE="000"
        MNEMO_RESPONSE="curl failed"
        return 1
    }

    MNEMO_RESPONSE="$(cat "$tmp_resp")"
    rm -f "$tmp_resp" "$tmp_body"
    MNEMO_HTTP_CODE="$http_code"

    # 2xx = success
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        return 0
    else
        return 1
    fi
}

_mnemo_format_error() {
    # Format an API error for display. Handles 402 (credits exhausted) specially.
    # Usage: _mnemo_format_error [context]
    #   context: optional label like "save" or "search"
    local context="${1:-request}"
    if [[ "$MNEMO_HTTP_CODE" == "402" ]]; then
        echo "Credits exhausted. Your Mnemo subscription has run out of API credits." >&2
        echo "Visit https://mmryai.com or contact your admin to add more credits." >&2
    else
        echo "Error (HTTP ${MNEMO_HTTP_CODE}): ${MNEMO_RESPONSE}" >&2
    fi
}

# ============================================================================
# 5. JSON HELPERS
# ============================================================================

_mnemo_json_escape() {
    # Escape a string for JSON embedding
    local s="$1"
    s="${s//\\/\\\\}"       # backslash
    s="${s//\"/\\\"}"       # double quote
    s="${s//$'\n'/\\n}"     # newline
    s="${s//$'\r'/\\r}"     # carriage return
    s="${s//$'\t'/\\t}"     # tab
    printf '%s' "$s"
}

_mnemo_build_json() {
    # Build a JSON object from key-value pairs
    # Usage: _mnemo_build_json key1 val1 key2 val2 ...
    # Prefix key with # for integer values (no quotes): #key val
    # Empty values are skipped
    local json="{"
    local first=true

    while [[ $# -ge 2 ]]; do
        local key="$1"
        local val="$2"
        shift 2

        # Skip empty values
        [[ -z "$val" ]] && continue || true

        if [[ "$first" == "true" ]]; then
            first=false
        else
            json+=","
        fi

        # Check for integer prefix
        if [[ "$key" == \#* ]]; then
            key="${key:1}"
            json+="\"${key}\":${val}"
        else
            local escaped
            escaped="$(_mnemo_json_escape "$val")"
            json+="\"${key}\":\"${escaped}\""
        fi
    done

    json+="}"
    echo -n "$json"
}

# ============================================================================
# 6. API WRAPPERS
# ============================================================================

mnemo_create_memory() {
    # Usage: mnemo_create_memory TIER CATEGORY SCOPE TOPIC CONTENT [SOURCE] [TASK_ID] [WORKING_DIR] [PROJECT_ID] [SESSION_ID] [VISIBILITY] [PERMISSION_GROUP_ID] [SUPERSEDES_ID]
    local tier="$1" category="$2" scope="$3" topic="$4" content="$5"
    local source="${6:-}" task_id="${7:-}" working_dir="${8:-}"
    local project_id="${9:-}" session_id="${10:-}" visibility="${11:-}"
    local permission_group_id="${12:-}" supersedes_id="${13:-}"

    local body
    body="$(_mnemo_build_json \
        "memoryTier" "$tier" \
        "category" "$category" \
        "scope" "$scope" \
        "topic" "$topic" \
        "content" "$content" \
        "source" "$source" \
        "taskDisplayID" "$task_id" \
        "workingDirectory" "$working_dir" \
        "#projectID" "$project_id" \
        "sessionID" "$session_id" \
        "visibility" "$visibility" \
        "#permissionGroupID" "$permission_group_id" \
        "#supersedesId" "$supersedes_id")"

    _mnemo_request POST "/api/memories" "$body"
}

mnemo_get_memories() {
    # Usage: mnemo_get_memories [WORKING_DIR] [SCOPE] [PROJECT_ID] [TIER] [STARTUP_MODE]
    local working_dir="${1:-}" scope="${2:-}" project_id="${3:-}"
    local tier="${4:-}" startup_mode="${5:-}"

    local query=""
    [[ -n "$working_dir" ]] && query+="workingDirectory=$(_mnemo_urlencode "$working_dir")&" || true
    [[ -n "$scope" ]] && query+="scope=${scope}&" || true
    [[ -n "$project_id" ]] && query+="projectId=${project_id}&" || true
    [[ -n "$tier" ]] && query+="tier=${tier}&" || true
    [[ -n "$startup_mode" ]] && query+="startupMode=${startup_mode}&" || true

    # Remove trailing &
    query="${query%&}"
    local path="/api/memories"
    [[ -n "$query" ]] && path+="?${query}" || true

    _mnemo_request GET "$path"
}

mnemo_get_startup_memories() {
    # Usage: mnemo_get_startup_memories [WORKING_DIR] [SCOPE] [PROJECT_ID]
    local working_dir="${1:-}" scope="${2:-}" project_id="${3:-}"

    local query=""
    [[ -n "$working_dir" ]] && query+="workingDirectory=$(_mnemo_urlencode "$working_dir")&" || true
    [[ -n "$scope" ]] && query+="scope=${scope}&" || true
    [[ -n "$project_id" ]] && query+="projectId=${project_id}&" || true
    query="${query%&}"

    local path="/api/memories/startup"
    [[ -n "$query" ]] && path+="?${query}" || true

    _mnemo_request GET "$path"
}

mnemo_get_memory_by_id() {
    # Usage: mnemo_get_memory_by_id ID
    _mnemo_request GET "/api/memories/$1"
}

mnemo_search_memories() {
    # Usage: mnemo_search_memories KEYWORDS [SCOPE] [PROJECT_ID]
    local keywords="$1" scope="${2:-}" project_id="${3:-}"

    # URL-encode keywords
    local encoded_q
    encoded_q="$(printf '%s' "$keywords" | sed 's/ /%20/g; s/&/%26/g; s/=/%3D/g; s/?/%3F/g; s/#/%23/g')"

    local query="q=${encoded_q}"
    [[ -n "$scope" ]] && query+="&scope=${scope}" || true
    [[ -n "$project_id" ]] && query+="&projectId=${project_id}" || true

    _mnemo_request GET "/api/memories/search?${query}"
}

mnemo_deactivate_memory() {
    # Usage: mnemo_deactivate_memory ID
    _mnemo_request DELETE "/api/memories/$1"
}

mnemo_reinforce_memory() {
    # Usage: mnemo_reinforce_memory ID
    _mnemo_request POST "/api/memories/$1/reinforce"
}

mnemo_create_link() {
    # Usage: mnemo_create_link SOURCE_ID TARGET_ID LINK_TYPE
    local body
    body="$(_mnemo_build_json \
        "#targetMemoryId" "$2" \
        "linkType" "$3")"
    _mnemo_request POST "/api/memories/$1/links" "$body"
}

mnemo_delete_link() {
    # Usage: mnemo_delete_link SOURCE_ID TARGET_ID
    _mnemo_request DELETE "/api/memories/$1/links/$2"
}

mnemo_get_related() {
    # Usage: mnemo_get_related MEMORY_ID
    _mnemo_request GET "/api/memories/$1/related"
}

mnemo_register_session() {
    # Usage: mnemo_register_session SESSION_ID CLIENT_NAME [WORKING_DIR] [PROJECT_ID]
    local body
    body="$(_mnemo_build_json \
        "sessionId" "$1" \
        "clientName" "$2" \
        "workingDirectory" "${3:-}" \
        "#projectId" "${4:-}")"
    _mnemo_request POST "/api/sessions" "$body"
}

mnemo_get_active_sessions() {
    _mnemo_request GET "/api/sessions/active"
}

mnemo_submit_feedback() {
    # Usage: mnemo_submit_feedback TYPE TITLE DESCRIPTION [COMPONENT] [REPRO_STEPS] [ENVIRONMENT]
    local type="$1" title="$2" description="$3"
    local component="${4:-}" repro_steps="${5:-}" environment="${6:-}"

    local body
    body="$(_mnemo_build_json \
        "type" "$type" \
        "title" "$title" \
        "description" "$description" \
        "component" "$component" \
        "reproSteps" "$repro_steps" \
        "environment" "$environment")"

    _mnemo_request POST "/api/feedback" "$body"
}

mnemo_health() {
    # Health check — does not require auth
    local tmp_resp
    tmp_resp="$(mktemp "${MNEMO_TMPDIR}/mnemo-health-XXXXXX")"
    MNEMO_HTTP_CODE=$(curl -s -o "$tmp_resp" -w '%{http_code}' \
        --connect-timeout 10 --max-time 25 \
        "${MNEMO_API_URL}/api/health")
    MNEMO_RESPONSE="$(cat "$tmp_resp")"
    rm -f "$tmp_resp"
    [[ "$MNEMO_HTTP_CODE" =~ ^2[0-9][0-9]$ ]]
}

# ============================================================================
# 7. AUTO-INIT
# ============================================================================

mnemo_load_config
