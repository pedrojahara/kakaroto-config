# Phase 1: Understand

You are investigating a bug in a clean context. Your ONLY deliverable is a diagnosis file at `.claude/resolve-diagnosis.md`.

## The Bug

Read the bug description from your launch prompt. That is your starting point.

## How to Investigate

Use any tools at your disposal. No prescribed steps. You decide the investigation path.

- Read files, grep for patterns, run the code, check logs, add temporary console.logs — whatever gets you to the root cause fastest.
- Search memory if relevant: `mcp__memory__search_nodes` for architectural context, known issues, or path conventions.
- Read project CLAUDE.md for structure and conventions.

## Anti-Anchoring Rule (MANDATORY)

Your first hypothesis is probably wrong. LLMs anchor on the first explanation 93% of the time.

Before concluding your investigation, you MUST:

1. Generate **at least 2 genuinely different hypotheses** for the root cause
2. For EACH hypothesis, document:
   - **Evidence For**: what supports this hypothesis
   - **Evidence Against**: what contradicts it (this column is MANDATORY — if you can't find counter-evidence, you haven't looked hard enough)
3. Only then select the most likely root cause based on evidence weight

Do NOT skip this. Do NOT generate 2 variations of the same idea. The hypotheses must be **structurally different** (e.g., "missing null check" vs "race condition" vs "wrong API endpoint").

## Reproduction Test

Write a test that **FAILS** right now, proving the bug exists:

- Place it where the project's test convention expects it
- The test name should clearly describe the expected behavior (not the bug)
- Run it and confirm it FAILS with `npm test`
- If the bug is untestable via unit/integration test, document WHY in the diagnosis and describe the manual reproduction steps instead

## Escape Hatch: Trivial Bugs

If the bug is trivially simple (typo, wrong variable name, off-by-one, missing import) AND you are >95% confident:

1. Fix it directly
2. Run `npm test` and `npx tsc --noEmit` to confirm the fix works
3. Write the diagnosis file with `Trivial Fix Applied: YES`
4. STOP — do not continue to Phase 2

## Deliverable

Write `.claude/resolve-diagnosis.md` with this structure (keep it compressed, ~1000-2000 tokens):

```markdown
# Diagnosis

## Bug
<one-line summary>

## Root Cause
<clear explanation of WHY the bug happens>

## Hypotheses Considered
| # | Hypothesis | Evidence For | Evidence Against | Verdict |
|---|-----------|-------------|-----------------|---------|
| 1 | ... | ... | ... | SELECTED / REJECTED |
| 2 | ... | ... | ... | SELECTED / REJECTED |

## Reproduction Test
- File: <path to test file>
- Test name: <test name>
- Current status: RED (fails as expected)

## Verification Method
<HOW to verify E2E that the fix actually works>
- Type: <Playwright | curl | bash | manual>
- Steps: <specific steps to verify>

## Suggested Fix
<brief description of the fix approach — do NOT implement it, Phase 2 will>

## Trivial Fix Applied: NO
```

If you applied the trivial escape hatch, change the last line to `YES` and add:

```markdown
## Fix Applied
<what you changed and why>

## Verification
<test results confirming the fix>
```

## Constraints

- Do NOT fix the bug (unless trivial escape hatch applies)
- Do NOT modify production code (test files are ok)
- Keep the diagnosis COMPRESSED — Phase 2 agent reads this as its only context
- If you cannot reproduce the bug after thorough investigation, write the diagnosis explaining what you tried and why reproduction failed
