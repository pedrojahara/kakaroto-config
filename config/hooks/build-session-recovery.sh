#!/bin/bash
# SessionStart hook: detects stalled /build and /resolve workflows.
# Uses .build-owner file age as heartbeat — if recent, another session is alive.
STALE_THRESHOLD=1800  # 30 minutes in seconds

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$CWD" ] && cd "$CWD"

for dir in .workflow/build/*/; do
  [ -d "$dir" ] || continue
  SPEC="$dir/spec.md"
  [ -f "$SPEC" ] || continue
  STATUS=$(grep -m1 '^Status:' "$SPEC" | sed 's/Status: *//')
  case "$STATUS" in
    DRAFTING|UNDERSTOOD|VERIFIED|BUILDING|CERTIFYING)
      SLUG=$(basename "$dir")
      OWNER_FILE="$dir/.build-owner"

      if [ -f "$OWNER_FILE" ]; then
        # Check file age (heartbeat). Stop hook touches this file every time it blocks.
        OWNER_MTIME=$(stat -f %m "$OWNER_FILE" 2>/dev/null || stat -c %Y "$OWNER_FILE" 2>/dev/null || echo 0)
        NOW=$(date +%s)
        AGE=$(( NOW - OWNER_MTIME ))

        if [ "$AGE" -lt "$STALE_THRESHOLD" ]; then
          # Recent heartbeat — another session is actively working
          OWNER_ID=$(cat "$OWNER_FILE")
          echo "=== /build OWNED BY ACTIVE SESSION ==="
          echo "Slug: $SLUG | Status: $STATUS | Owner: $OWNER_ID"
          echo "Last heartbeat: ${AGE}s ago. Another Claude session is working on this build."
          echo "Do NOT resume — let the other session finish."
          echo "=== END ==="
          exit 0
        fi

        # Stale heartbeat — session probably died. Safe to reclaim.
        rm -f "$OWNER_FILE"
      fi

      # No owner (or stale owner removed) — genuinely stalled
      echo "=== STALLED /build WORKFLOW ==="
      echo "Slug: $SLUG | Status: $STATUS"
      echo "ACTION: Resume with /build $SLUG"
      [ -f "$dir/next-action.md" ] && echo "Next action:" && cat "$dir/next-action.md"
      echo "=== END ==="
      exit 0 ;;
  esac
done

# Same logic for /resolve workflows (status in diagnosis.md instead of spec.md)
for dir in .workflow/resolve/*/; do
  [ -d "$dir" ] || continue
  DIAG="$dir/diagnosis.md"
  [ -f "$DIAG" ] || continue
  STATUS=$(grep -m1 '^Status:' "$DIAG" | sed 's/Status: *//')
  case "$STATUS" in
    INVESTIGATING|DIAGNOSED|VERIFIED|FIXING|CERTIFYING)
      SLUG=$(basename "$dir")
      OWNER_FILE="$dir/.build-owner"

      if [ -f "$OWNER_FILE" ]; then
        OWNER_MTIME=$(stat -f %m "$OWNER_FILE" 2>/dev/null || stat -c %Y "$OWNER_FILE" 2>/dev/null || echo 0)
        NOW=$(date +%s)
        AGE=$(( NOW - OWNER_MTIME ))

        if [ "$AGE" -lt "$STALE_THRESHOLD" ]; then
          OWNER_ID=$(cat "$OWNER_FILE")
          echo "=== /resolve OWNED BY ACTIVE SESSION ==="
          echo "Slug: $SLUG | Status: $STATUS | Owner: $OWNER_ID"
          echo "Last heartbeat: ${AGE}s ago. Another Claude session is working on this resolve."
          echo "Do NOT resume — let the other session finish."
          echo "=== END ==="
          exit 0
        fi

        rm -f "$OWNER_FILE"
      fi

      echo "=== STALLED /resolve WORKFLOW ==="
      echo "Slug: $SLUG | Status: $STATUS"
      echo "ACTION: Resume with /resolve $SLUG"
      [ -f "$dir/next-action.md" ] && echo "Next action:" && cat "$dir/next-action.md"
      echo "=== END ==="
      exit 0 ;;
  esac
done
exit 0
