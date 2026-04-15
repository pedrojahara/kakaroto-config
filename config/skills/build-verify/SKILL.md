---
name: build-verify
description: "Verification designer for /build. Designs QA test scripts (executed via Playwright MCP) and confirms with user via AskUserQuestion."
user-invocable: false
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - ToolSearch
  - AskUserQuestion
  - mcp__memory__search_nodes
---

# VERIFY — Design QA Test Scripts

Design QA test flows for the feature. Think like a human QA tester, but these flows
are executed automatically by the LLM via Playwright MCP tools.

**Input:** `$ARGUMENTS` = `{slug}`. Spec at `.workflow/build/{slug}/spec.md` with Status: UNDERSTOOD.

## Boundaries

- **Authority:** ONLY set Status to `VERIFIED`.
- **Write scope:** `.workflow/build/{slug}/spec.md` and `.workflow/build/verify.sh`.

---

## Step 0: LOAD TOOLS

Ensure AskUserQuestion is available: `ToolSearch("select:AskUserQuestion", max_results: 1)`

---

## Step 1: Read Spec

Read `.workflow/build/{slug}/spec.md`. Understand what was approved. If helpful, explore relevant pages/components to understand the UI surface.

## Step 2: Design QA Verification

The verification system has two layers — you design the second one:

- **V1-V3 (automatic):** Unit tests, TypeScript, build. Already handled by verify.sh. Don't design these.
- **V4+ (your job):** What a human QA would test — visual correctness, user flows, states, edge cases. These are executed by the LLM using Playwright MCP tools.

Design V4+ as QA test scripts. Think: **what would convince a skeptical user that this works?**

```
V4: {Test name}
  - steps:
    1. Open [page/URL]
    2. Click [button/element]
    3. Fill [field] with [value]
    4. Verify [expected result visible on screen]
  - checks:
    - console: no-errors
    - url: contains "[expected path]"
    - text: visible "[key text that proves success]"
    - text: not-visible "[text that indicates failure]"
    - state: no-loading
```

Every step must be a concrete, observable action.

### Checks DSL

Checks are **deterministic safety nets** executed via `browser_evaluate` / `browser_console_messages` after the LLM completes all steps. They supplement prose steps — they don't replace them.

| Type                    | Syntax        | What it verifies                      |
| ----------------------- | ------------- | ------------------------------------- |
| `console: no-errors`    | Fixed         | No error-level console messages       |
| `url: contains "X"`     | Parameterized | Current URL includes string X         |
| `text: visible "X"`     | Parameterized | Page text contains X                  |
| `text: not-visible "X"` | Parameterized | Page text does NOT contain X          |
| `state: no-loading`     | Fixed         | No spinners/loading indicators active |

Rules:

- Every V4+ flow SHOULD have checks (recommended, not mandatory)
- At minimum include `console: no-errors` — catches the most common false positives
- Use `text: visible` for the KEY outcome, not every piece of text on the page
- Checks don't require DOM knowledge — they use generic text/URL/console patterns

## Step 3: Ask for Approval

Call AskUserQuestion with this exact structure:

- question: "Você aprova os scripts de verificação V4+ abaixo?"
- header: "QA Approval"
- multiSelect: false
- options:
  1. label: "Aprovar verificações (Recommended)"
     description: "Os scripts estão corretos, pode prosseguir"
     preview: **PASTE ALL V4+ SCRIPTS HERE** — the complete scripts from Step 2, every step, no abbreviation. Use markdown formatting.
  2. label: "Precisa de ajustes"
     description: "Algo precisa ser mudado nos scripts de verificação"

**CRITICAL:** The `preview` field on the first option MUST contain the FULL V4+ scripts designed in Step 2.
Without this, the user CANNOT see what they are approving. The preview renders as a side-by-side panel in the UI.

### If "Approve verifications"

1. Add `## Verification` section to `.workflow/build/{slug}/spec.md` (before `## Source`). Set Status → `VERIFIED`.
2. Read `${CLAUDE_SKILL_DIR}/verify-template.md`. Write `.workflow/build/verify.sh` following the template — V1-V3 baselines only.
3. Return `{slug}: VERIFIED`

### If "Needs changes"

Read feedback, redesign V4+ scripts, re-ask. Max 3 loops.

## Output

Return ONLY: `{slug}: VERIFIED`
