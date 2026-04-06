#!/bin/bash
# PostToolUse guard: rejects empty AskUserQuestion responses.
# Reads tool result from stdin, checks if any answer is empty/blank.
# Outputs warning to stdout (injected as LLM feedback) if empty detected.
set -euo pipefail

INPUT=$(cat)

# Extract the tool result text
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_response // empty')

# Check for common empty-response patterns in the output
# AskUserQuestion returns answers as "question: answer" pairs
# An empty answer would show as empty string, whitespace, or "Other: "
if echo "$TOOL_OUTPUT" | grep -qE '^\s*$' 2>/dev/null; then
  echo "WARNING: AskUserQuestion received an EMPTY response. This is likely an accidental submission (user did not click Enter). You MUST re-ask the exact same question. Do NOT proceed as if the user approved."
  exit 0
fi

# Check for answers that are just whitespace or "Other" with no content
if echo "$TOOL_OUTPUT" | grep -qiE '"answer"\s*:\s*""' 2>/dev/null; then
  echo "WARNING: AskUserQuestion received a BLANK answer. This is likely an accidental submission. You MUST re-ask the exact same question. Do NOT proceed as if the user approved."
  exit 0
fi

# Check for the specific pattern where all answers are empty strings
if echo "$TOOL_OUTPUT" | jq -e 'if .answers then (.answers | to_entries | all(.value | test("^\\s*$"))) else false end' 2>/dev/null | grep -q true; then
  echo "WARNING: All AskUserQuestion answers are empty/blank. This is likely an accidental submission. You MUST re-ask the exact same question. Do NOT proceed as if the user approved."
  exit 0
fi

exit 0
