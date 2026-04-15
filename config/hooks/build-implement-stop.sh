#!/bin/bash
# Stop hook for build-implementer agent.
# Blocks stop if verify.sh --full fails for the active build.
set -euo pipefail

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_ACTIVE" = "true" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0
cd "$CWD"

VERIFY=".workflow/build/verify.sh"
if [ ! -f "$VERIFY" ]; then
  echo "Cannot stop: no verify.sh found." >&2
  exit 2
fi

SPEC=$(ls -t .workflow/build/*/spec.md 2>/dev/null | head -1)
if [ -z "$SPEC" ]; then
  bash "$VERIFY" "none"
  if [ $? -ne 0 ]; then exit 2; fi
  exit 0
fi

SLUG=$(echo "$SPEC" | sed 's|.*\.workflow/build/||;s|/spec.md||')
bash "$VERIFY" "$SLUG" --full
if [ $? -ne 0 ]; then
  echo "Cannot stop: verify.sh --full failed for build $SLUG." >&2
  echo "Run ALL V4+ tests via Playwright MCP against localhost:3001, then create marker:" >&2
  echo "  date -u '+%Y-%m-%dT%H:%M:%SZ' > .workflow/build/$SLUG/v4-passed" >&2
  exit 2
fi
exit 0
