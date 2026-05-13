#!/usr/bin/env bash
# Run Mnemo plugin tests
# Usage: ./run-tests.sh [category]
#   category: structural, unit, handlers, e2e, integration, all, offline (default)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CATEGORY="${1:-offline}"
BATS="./libs/bats-core/bin/bats"

if [[ ! -x "$BATS" ]]; then
    echo "Error: BATS not found. Run 'git submodule update --init --recursive' first." >&2
    exit 1
fi

case "$CATEGORY" in
    structural)  "$BATS" structural/ ;;
    unit)        "$BATS" unit/ ;;
    handlers)    "$BATS" handlers/ ;;
    e2e)         "$BATS" e2e/ ;;
    integration) "$BATS" integration/ ;;
    offline)     "$BATS" structural/ unit/ handlers/ e2e/ ;;
    all)         "$BATS" structural/ unit/ handlers/ e2e/ integration/ ;;
    *)
        echo "Usage: $0 [structural|unit|handlers|e2e|integration|offline|all]" >&2
        exit 1
        ;;
esac
