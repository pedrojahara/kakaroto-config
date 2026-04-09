#!/bin/bash
# PreToolUse hook for Skill: registers ownership when a build/resolve sub-skill is invoked.
# This is the ONLY place ownership is claimed. The Stop hook only reads .build-owner.
INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

case "$SKILL" in
  build-implement|build-verify|build-certify|build-understand)
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
    ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // empty')
    SLUG=$(echo "$ARGS" | awk '{print $1}')

    [ -z "$SESSION_ID" ] || [ -z "$SLUG" ] && exit 0

    OWNER_DIR="$CWD/.workflow/build/$SLUG"
    mkdir -p "$OWNER_DIR"
    echo "$SESSION_ID" > "$OWNER_DIR/.build-owner"
    ;;
  resolve-investigate|resolve-verify|resolve-fix|resolve-certify)
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
    ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // empty')
    SLUG=$(echo "$ARGS" | awk '{print $1}')

    [ -z "$SESSION_ID" ] || [ -z "$SLUG" ] && exit 0

    OWNER_DIR="$CWD/.workflow/resolve/$SLUG"
    mkdir -p "$OWNER_DIR"
    echo "$SESSION_ID" > "$OWNER_DIR/.build-owner"
    ;;
esac
exit 0
