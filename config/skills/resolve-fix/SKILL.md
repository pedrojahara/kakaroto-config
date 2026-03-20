---
name: resolve-fix
description: "Autonomous bug fixer. Fixes root cause, verifies via tests and QA flows."
context: fork
agent: resolve-fixer
user-invocable: false
model: opus
---

# FIX -- Resolve Root Cause + Local QA Verification

You receive `{slug}` from `$ARGUMENTS`.

## Boundaries

- **Authority:** You may ONLY set Status to `CERTIFYING` or `INVESTIGATING` (circuit breaker). Never write DIAGNOSED, VERIFIED, DONE, or FAILED.
- **Autonomous:** No user interaction. Resolve ambiguities using the diagnosis and the codebase.
- **Contract:** `diagnosis.md` is truth. The root cause and QA flows are your guide.

## Setup

1. Read `.claude/resolve/{slug}/diagnosis.md` -- this is your contract (WHAT is broken + HOW to verify)
2. Read the project's `CLAUDE.md` -- constraints and conventions
3. Search memory if relevant: `mcp__memory__search_nodes({ query: "relevant-pattern" })`
4. Read the Root Cause, Suggested Fix, Hotspots, and QA Reproduction Flows sections

## Fix

Make the **minimum change** that fixes the root cause. After each change:
```bash
npm test -- --run
npx tsc --noEmit
```

If the same approach fails twice, use Sequential Thinking to reconsider.

## Local QA Verification

After unit tests pass, execute ALL QA Reproduction Flows from the diagnosis via Playwright MCP against `http://localhost:3001`:

1. Ensure dev server is running (start if needed)
2. For each R1, R2...: follow human-steps exactly
3. Verify expected-fixed state is visible on screen
4. If any flow still shows the bug: fix is incomplete, iterate

## Circuit Breaker

Attempt 4 with no progress -> Update diagnosis Status -> `INVESTIGATING`. Write findings to fix-notes.md. Return `{slug}: RE-INVESTIGATE`. The orchestrator will re-invoke resolve-investigate with new context.

## Notes

Before signaling CERTIFYING, write `.claude/resolve/{slug}/fix-notes.md`:
- Approach chosen and why
- Rejected approaches
- Files changed with rationale
- QA verification results per flow
- Concerns and low-confidence areas

## Done

When `npm test -- --run` passes AND `npx tsc --noEmit` passes AND all QA flows pass via Playwright MCP:
- Status -> `CERTIFYING`
- fix-notes.md written
- Return ONLY: `{slug}: CERTIFYING`

**If the agent returns with Status still FIXING** (turn budget): read `.claude/resolve/{slug}/fix-notes.md`, then re-invoke resolve-fix -- the fresh agent reads the notes as prior context.

**If the agent returns with Status INVESTIGATING** (circuit breaker): orchestrator re-invokes resolve-investigate.

## Handoff

Before returning, write `.claude/resolve/{slug}/next-action.md` -- a single line:

If CERTIFYING:
```
Skill("resolve-certify", args: "{slug}")
```

If INVESTIGATING (circuit breaker):
```
Skill("resolve-investigate", args: "{slug} RE-INVESTIGATE: see fix-notes.md")
```
