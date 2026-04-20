#!/bin/bash
# PermissionDenied hook: logs auto-mode classifier denials for visibility.
# Does NOT retry automatically — denials should be visible so the user can
# decide whether to explicitly allowlist the pattern.
set -euo pipefail

INPUT=$(cat)
LOG_DIR="$HOME/.claude/debug"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/permission-denied.log"

TS=$(date '+%Y-%m-%d %H:%M:%S')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "?"' 2>/dev/null || echo "?")
REASON=$(echo "$INPUT" | jq -r '.reason // .denial_reason // .message // "auto-mode classifier"' 2>/dev/null || echo "?")
SESSION=$(echo "$INPUT" | jq -r '.session_id // "?"' 2>/dev/null || echo "?")
INPUT_SUMMARY=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null | head -c 500)

echo "[$TS] session=$SESSION tool=$TOOL reason=\"$REASON\" input=$INPUT_SUMMARY" >> "$LOG"
exit 0
