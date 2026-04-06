#!/bin/bash
# Stop hook: prevents the owning session from stopping while /build or /resolve is active.
# Reads next-action.md directly and injects the exact Skill() call.
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

for dir in "$CWD"/.workflow/build/*/; do
  [ -d "$dir" ] || continue
  NA="$dir/next-action.md"
  OWNER="$dir/.build-owner"

  # No next-action → clean up stale owner
  if [ ! -f "$NA" ]; then
    rm -f "$OWNER"
    continue
  fi

  # next-action.md exists — only block if we're the owner
  if [ -f "$OWNER" ] && [ "$(cat "$OWNER")" = "$SESSION_ID" ]; then
    touch "$OWNER"
    SLUG=$(basename "$dir")
    ACTION=$(head -1 "$NA" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if echo "$ACTION" | grep -qE '^Skill\('; then
      log "BLOCK: slug=$SLUG action=$ACTION"
      echo "STOP BLOCKED — Execute immediately: $ACTION"
      exit 2
    else
      log "DEGRADE: slug=$SLUG action='$ACTION' (not Skill call)"
      exit 0
    fi
  fi
done

# Same logic for /resolve workflows
for dir in "$CWD"/.workflow/resolve/*/; do
  [ -d "$dir" ] || continue
  NA="$dir/next-action.md"
  OWNER="$dir/.build-owner"

  # No next-action -> clean up stale owner
  if [ ! -f "$NA" ]; then
    rm -f "$OWNER"
    continue
  fi

  # next-action.md exists -- only block if we're the owner
  if [ -f "$OWNER" ] && [ "$(cat "$OWNER")" = "$SESSION_ID" ]; then
    touch "$OWNER"
    SLUG=$(basename "$dir")
    ACTION=$(head -1 "$NA" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if echo "$ACTION" | grep -qE '^Skill\('; then
      log "BLOCK: resolve slug=$SLUG action=$ACTION"
      echo "STOP BLOCKED — Execute immediately: $ACTION"
      exit 2
    else
      log "DEGRADE: resolve slug=$SLUG action='$ACTION' (not Skill call)"
      exit 0
    fi
  fi
done

log "PASS: no owned builds/resolves for session=$SESSION_ID"
exit 0
