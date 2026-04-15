#!/bin/bash
# PreToolUse hook for Bash: blocks git commit if quality checks fail.
# Deterministic enforcement of rules that are advisory in CLAUDE.md/prompts.
# Exit 2 = block action + feed error back to Claude for auto-correction.
#
# Phase 1: Auto-format with prettier (fix, don't block)
# Phase 2: Prohibit TypeScript `any` type
# Phase 3: TypeScript compilation (tsc --noEmit)
# Phase 4: Tests (npm test)
set -euo pipefail

INPUT=$(cat)

# Only intercept git commit commands
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
echo "$COMMAND" | grep -qE '\bgit\s+commit\b' || exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0
cd "$CWD"

ERRORS=""

# --- Phase 1: Auto-format with prettier (fix, don't block) ---
if command -v npx >/dev/null 2>&1 && npx prettier --version >/dev/null 2>&1; then
  STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|json|css|scss|md)$' || true)
  if [ -n "$STAGED" ]; then
    echo "$STAGED" | tr '\n' '\0' | xargs -0 npx prettier --write --log-level=error 2>/dev/null || true
    echo "$STAGED" | tr '\n' '\0' | xargs -0 git add 2>/dev/null || true
  fi
fi

# --- Phase 2: Prohibit TypeScript `any` type ---
STAGED_TS=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.(ts|tsx)$' || true)
if [ -n "$STAGED_TS" ]; then
  # Check added lines for `any` type usage (excluding comments and imports)
  # shellcheck disable=SC2086
  ANY_VIOLATIONS=$(git diff --cached -U0 -- $STAGED_TS 2>/dev/null | \
    grep -E '^\+' | grep -v '^\+\+\+' | \
    grep -E '\bany\b' | \
    grep -v -E '^\+\s*(//|/?\*|import\b|require\b)' || true)
  if [ -n "$ANY_VIOLATIONS" ]; then
    ERRORS="${ERRORS}\n\n:: TypeScript \`any\` type detected in staged changes:\n${ANY_VIOLATIONS}\nReplace with proper types (unknown, specific type, or generic)."
  fi
fi

# --- Phase 3: TypeScript compilation ---
if [ -f "tsconfig.json" ] && command -v npx >/dev/null 2>&1; then
  TSC_OUTPUT=$(npx tsc --noEmit 2>&1) || {
    ERRORS="${ERRORS}\n\n:: TypeScript compilation errors:\n${TSC_OUTPUT}"
  }
fi

# --- Phase 4: Tests ---
if [ -f "package.json" ] && jq -e '.scripts.test' package.json >/dev/null 2>&1; then
  TEST_OUTPUT=$(CI=true npm test 2>&1) || {
    ERRORS="${ERRORS}\n\n:: Tests failing:\n$(echo "$TEST_OUTPUT" | tail -30)"
  }
fi

# --- Result ---
if [ -n "$ERRORS" ]; then
  echo -e "PRE-COMMIT GATE FAILED — fix before committing:${ERRORS}"
  exit 2
fi

exit 0
