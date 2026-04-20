#!/bin/bash
# PreCompact hook: refreshes heartbeat on active build/resolve workflows
# so build-session-recovery.sh does not flag them stale after compaction.
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null || exit 0

LOG="/tmp/pre-compact-$(date +%Y%m%d).log"
TS=$(date '+%H:%M:%S')

REFRESHED=0
for owner in .workflow/build/*/.build-owner .workflow/resolve/*/.build-owner; do
  [ -f "$owner" ] || continue
  touch "$owner"
  REFRESHED=$((REFRESHED + 1))
done

echo "[$TS] pre-compact in $CWD — refreshed $REFRESHED owner heartbeat(s)" >> "$LOG" 2>/dev/null || true
exit 0
