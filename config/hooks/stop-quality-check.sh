#!/bin/bash
# Stop hook: blocks stop if there are code changes with quality issues.
# Complements build-stop-guard.sh (which handles workflow orchestration).
# This hook covers ad-hoc sessions outside of /build and /resolve.
#
# Skip conditions:
# - stop_hook_active=true (recursive guard)
# - Not a Node.js project (no package.json)
# - Active workflow session (build-stop-guard.sh handles those)
# - No code changes (read-only/explanation session)
set -euo pipefail

INPUT=$(cat)

# Respect stop_hook_active flag
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_ACTIVE" = "true" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0
cd "$CWD"

# Skip if not a Node.js project
[ -f "package.json" ] || exit 0

# Skip if active workflow (build-stop-guard.sh handles these)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [ -n "$SESSION_ID" ]; then
  for owner in "$CWD"/.workflow/build/*/.build-owner "$CWD"/.workflow/resolve/*/.build-owner; do
    if [ -f "$owner" ] 2>/dev/null && [ "$(cat "$owner" 2>/dev/null)" = "$SESSION_ID" ]; then
      exit 0
    fi
  done
fi

# Skip if no code changes (staged, unstaged, or untracked .ts/.tsx/.js/.jsx)
HAS_CHANGES=false
git diff --quiet HEAD 2>/dev/null || HAS_CHANGES=true
git diff --cached --quiet 2>/dev/null || HAS_CHANGES=true
if [ "$HAS_CHANGES" = "false" ]; then
  UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' | head -1 || true)
  [ -n "$UNTRACKED" ] && HAS_CHANGES=true
fi
[ "$HAS_CHANGES" = "false" ] && exit 0

ERRORS=""

# TypeScript check
if [ -f "tsconfig.json" ] && command -v npx >/dev/null 2>&1; then
  TSC_OUTPUT=$(npx tsc --noEmit 2>&1) || {
    ERRORS="${ERRORS}\n\n:: TypeScript errors:\n${TSC_OUTPUT}"
  }
fi

# Test check
if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
  TEST_OUTPUT=$(CI=true npm test 2>&1) || {
    ERRORS="${ERRORS}\n\n:: Tests failing:\n$(echo "$TEST_OUTPUT" | tail -30)"
  }
fi

if [ -n "$ERRORS" ]; then
  echo -e "STOP BLOCKED — uncommitted code changes have quality issues:${ERRORS}\nFix before stopping, or commit first."
  exit 2
fi

exit 0
