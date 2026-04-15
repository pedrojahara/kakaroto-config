#!/bin/bash
# PostToolUse guard: rejects empty AskUserQuestion responses.
# Reads tool result from stdin, checks if any answer is empty/blank.
# Outputs warning to stdout (injected as LLM feedback) if empty detected.
set -euo pipefail

INPUT=$(cat)

# Extract the tool result text
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_response // empty')

# Detect empty responses: blank text, empty JSON answer, or all-blank answers array
IS_EMPTY=false
echo "$TOOL_OUTPUT" | grep -qE '^\s*$' 2>/dev/null && IS_EMPTY=true
echo "$TOOL_OUTPUT" | grep -qiE '"answer"\s*:\s*""' 2>/dev/null && IS_EMPTY=true
echo "$TOOL_OUTPUT" | jq -e 'if .answers then (.answers | to_entries | all(.value | test("^\\s*$"))) else false end' 2>/dev/null | grep -q true && IS_EMPTY=true

if [ "$IS_EMPTY" = "true" ]; then
  echo "WARNING: AskUserQuestion received an EMPTY response. This is likely an accidental submission. You MUST re-ask the exact same question. Do NOT proceed as if the user approved."
  exit 0
fi

exit 0
