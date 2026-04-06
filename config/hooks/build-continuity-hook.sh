#!/bin/bash
# PostToolUse hook for Skill: injects continuation instructions after build/resolve sub-skills.
# Prevents the LLM from "narrating" between sub-skill transitions.
#
# 3-GATE SESSION ISOLATION:
# Gate 1: skill-name filter (only build/resolve sub-skills)
# Gate 2: slug-from-args (scopes to correct build/resolve directory)
# Gate 3: session ownership (.build-owner == session_id)
set -euo pipefail

LOG="/tmp/build-continuity-$(date +%Y%m%d).log"
log() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG" 2>/dev/null || true; }

INPUT=$(cat)

SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')

# Gate 1: only process build/resolve sub-skills
TYPE=""
case "$SKILL" in
  build-understand|build-plan-spec|build-verify|build-implement|build-plan-implement|build-certify)
    TYPE="build" ;;
  resolve-investigate|resolve-verify|resolve-fix|resolve-certify)
    TYPE="resolve" ;;
  *)
    exit 0 ;;
esac

# Terminal state guard: don't inject for completed workflows
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')
if echo "$RESPONSE" | grep -qE '(^DONE:|VERIFIED_PROD|CANCELLED)'; then
  log "SKIP: terminal state for $SKILL"
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // empty')
SLUG=$(echo "$ARGS" | awk '{print $1}')

# Gate 2: need slug to scope to correct directory
if [ -z "$CWD" ] || [ -z "$SLUG" ]; then
  log "SKIP: missing cwd or slug for $SKILL"
  exit 0
fi

# Gate 3: session ownership
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
OWNER_FILE="$CWD/.workflow/$TYPE/$SLUG/.build-owner"

if [ ! -f "$OWNER_FILE" ] || [ "$(cat "$OWNER_FILE" 2>/dev/null)" != "$SESSION_ID" ]; then
  log "SKIP: not owner for $TYPE/$SLUG (session=$SESSION_ID)"
  exit 0
fi

# Compute next action — specific when deterministic, generic otherwise
NEXT=""
SPEC_FILE="$CWD/.workflow/$TYPE/$SLUG/spec.md"

case "$SKILL" in
  build-understand|build-plan-spec)
    if [ -f "$SPEC_FILE" ]; then
      COMPLEXITY=$(grep -m1 '^Complexity:' "$SPEC_FILE" 2>/dev/null | sed 's/^Complexity:[[:space:]]*//' || echo "")
      if [ "$COMPLEXITY" = "FULL" ]; then
        NEXT="Execute: Skill(\"build-verify\", args: \"$SLUG\")"
      elif [ "$COMPLEXITY" = "LITE" ]; then
        NEXT="Edit spec Status to BUILDING, then execute the implement skill per the algorithm."
      fi
    fi
    ;;
  build-verify)
    NEXT="Edit spec Status to BUILDING, then execute the implement skill per the orchestrator algorithm."
    ;;
  build-implement|build-plan-implement)
    NEXT="Execute: Skill(\"build-certify\", args: \"$SLUG\")"
    ;;
  build-certify)
    NEXT="Read spec Status and proceed per the algorithm."
    ;;
  resolve-investigate)
    NEXT="Proceed to the next step per the /resolve algorithm."
    ;;
  resolve-verify)
    NEXT="Edit Status to FIXING, then execute: Skill(\"resolve-fix\", args: \"$SLUG\")"
    ;;
  resolve-fix)
    NEXT="Proceed to the next step per the /resolve algorithm."
    ;;
  resolve-certify)
    NEXT="Read Status and proceed per the algorithm."
    ;;
esac

[ -z "$NEXT" ] && NEXT="Proceed to the next step per the orchestrator algorithm."

log "INJECT: $SKILL → $NEXT (slug=$SLUG)"

jq -n --arg ctx "CONTINUITY ENFORCEMENT: Your ONLY next action must be a tool call. Do NOT output text to the user. $NEXT" \
  '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": $ctx}}'
