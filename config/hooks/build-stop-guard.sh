#!/bin/bash
# Stop hook: prevents the owning session from stopping while /build or /resolve is active.
# Derives next action from spec/diagnosis Status (source of truth), with next-action.md as override.
#
# OWNERSHIP MODEL:
# - PreToolUse hook on Skill claims ownership when build/resolve sub-skills are invoked
# - This hook only checks existing .build-owner files
# - Other sessions always pass through freely
set -euo pipefail

LOG="/tmp/build-stop-guard-$(date +%Y%m%d).log"
log() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG" 2>/dev/null || true; }

INPUT=$(cat)

STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  log "SKIP: stop_hook_active=true"
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[ -z "$SESSION_ID" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

# Derive next action from spec.md Status for /build workflows
derive_build_action() {
  local SPEC="$1" SLUG="$2"
  local STATUS
  STATUS=$(grep -m1 '^Status:' "$SPEC" 2>/dev/null | sed 's/^Status:[[:space:]]*//' || echo "")

  case "$STATUS" in
    UNDERSTOOD)
      echo "Skill(\"build-verify\", args: \"$SLUG\")" ;;
    VERIFIED)
      echo "Edit spec Status to BUILDING, then execute the implement skill per the /build algorithm." ;;
    BUILDING)
      echo "Execute the implement skill per the /build algorithm for slug $SLUG." ;;
    CERTIFYING)
      echo "Skill(\"build-certify\", args: \"$SLUG\")" ;;
  esac
}

# Derive next action from diagnosis.md Status for /resolve workflows
derive_resolve_action() {
  local SPEC="$1" SLUG="$2"
  local STATUS
  STATUS=$(grep -m1 '^Status:' "$SPEC" 2>/dev/null | sed 's/^Status:[[:space:]]*//' || echo "")

  case "$STATUS" in
    DIAGNOSED)
      echo "Skill(\"resolve-verify\", args: \"$SLUG\")" ;;
    VERIFIED)
      echo "Edit Status to FIXING, then execute: Skill(\"resolve-fix\", args: \"$SLUG\")" ;;
    FIXING)
      echo "Skill(\"resolve-fix\", args: \"$SLUG\")" ;;
    CERTIFYING)
      echo "Skill(\"resolve-certify\", args: \"$SLUG\")" ;;
  esac
}

# Generic workflow checker for both /build and /resolve
check_workflow() {
  local TYPE="$1" SPEC_NAME="$2"

  for dir in "$CWD"/.workflow/$TYPE/*/; do
    [ -d "$dir" ] || continue
    local OWNER="$dir/.build-owner"

    # Only check workflows we own
    [ -f "$OWNER" ] && [ "$(cat "$OWNER" 2>/dev/null)" = "$SESSION_ID" ] || continue
    touch "$OWNER"

    local SLUG ACTION=""
    SLUG=$(basename "$dir")

    # Priority 1: next-action.md (explicit handoff from forked agent)
    local NA="$dir/next-action.md"
    if [ -f "$NA" ]; then
      ACTION=$(head -1 "$NA" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    fi

    # Priority 2: derive from spec/diagnosis Status
    if [ -z "$ACTION" ]; then
      local SPEC="$dir/$SPEC_NAME"
      if [ -f "$SPEC" ]; then
        case "$TYPE" in
          build)   ACTION=$(derive_build_action "$SPEC" "$SLUG") ;;
          resolve) ACTION=$(derive_resolve_action "$SPEC" "$SLUG") ;;
        esac
      fi
    fi

    # Block if action found
    if [ -n "$ACTION" ]; then
      log "BLOCK: $TYPE slug=$SLUG action=$ACTION"
      echo "STOP BLOCKED — Execute immediately: $ACTION"
      exit 2
    fi

    # No action → terminal state (DONE/CANCELLED/VERIFIED_PROD), clean up
    log "CLEAN: $TYPE slug=$SLUG (terminal state)"
    rm -f "$OWNER"
  done
}

check_workflow "build" "spec.md"
check_workflow "resolve" "diagnosis.md"

log "PASS: no owned builds/resolves for session=$SESSION_ID"
exit 0
