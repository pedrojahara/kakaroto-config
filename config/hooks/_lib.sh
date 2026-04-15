#!/bin/bash
# Shared functions for build/resolve workflow hooks.
# Source this file: source "$(dirname "$0")/_lib.sh"

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
