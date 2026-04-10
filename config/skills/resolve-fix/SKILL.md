---
name: resolve-fix
description: "Autonomous bug fixer. Fixes root cause, verifies via tests and QA flows."
context: fork
agent: resolve-fixer
user-invocable: false
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - mcp__sequential-thinking__sequentialthinking
  - mcp__memory__search_nodes
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - mcp__playwright__browser_navigate
  - mcp__playwright__browser_snapshot
  - mcp__playwright__browser_click
  - mcp__playwright__browser_fill_form
  - mcp__playwright__browser_type
  - mcp__playwright__browser_wait_for
  - mcp__playwright__browser_console_messages
  - mcp__playwright__browser_close
  - mcp__playwright__browser_take_screenshot
  - mcp__playwright__browser_tabs
  - mcp__playwright__browser_press_key
  - mcp__playwright__browser_hover
  - mcp__playwright__browser_select_option
  - mcp__playwright__browser_evaluate
  - mcp__playwright__browser_network_requests
  - mcp__playwright__browser_navigate_back
---

# FIX -- Resolve Root Cause + Local QA Verification

You receive `{slug}` from `$ARGUMENTS`.

## Boundaries

- **Authority:** You may ONLY set Status to `CERTIFYING` or `INVESTIGATING` (circuit breaker). Never write DIAGNOSED, VERIFIED, DONE, or FAILED.
- **Autonomous:** No user interaction. Resolve ambiguities using the diagnosis and the codebase.
- **Contract:** `diagnosis.md` is truth. The root cause and QA flows are your guide.

## Setup

1. Read `.workflow/resolve/{slug}/diagnosis.md` -- this is your contract (WHAT is broken + HOW to verify)
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

After unit tests pass, execute ALL QA Reproduction Flows from the diagnosis:

**Auth Discovery:** Read project CLAUDE.md `## Deploy` section for auth method and prod URL. Also search `mcp__memory__search_nodes({ query: "production-testing" })`.

- **Local browser:** Playwright MCP against `http://localhost:3001` (no auth needed in dev)
- **API testing:** Use the discovered auth method from CLAUDE.md
- **Production-only bugs:** If the bug only manifests in production, use discovered auth against the production URL. Check logs using the log command from CLAUDE.md `## Deploy` section.

Steps:

1. For browser-testable flows: ensure dev server is running, use Playwright MCP against localhost
2. For API-testable flows: use curl with appropriate auth
3. For each R1, R2...: follow human-steps exactly
4. Verify expected-fixed state
5. If any flow still shows the bug: fix is incomplete, iterate

## Circuit Breaker

Attempt 4 with no progress OR WTF-likelihood >= 30% -> Update diagnosis Status -> `INVESTIGATING`. Write findings to fix-notes.md. Return `{slug}: RE-INVESTIGATE`. The orchestrator will re-invoke resolve-investigate with new context.

## Notes

Before signaling CERTIFYING, write `.workflow/resolve/{slug}/fix-notes.md`:

- Approach chosen and why
- Rejected approaches
- Files changed with rationale
- QA verification results per flow
- Concerns and low-confidence areas

## Done

When `npm test -- --run` passes AND `npx tsc --noEmit` passes AND regression test exists for the fix AND all QA flows pass via Playwright MCP:

- Status -> `CERTIFYING`
- fix-notes.md written
- Do NOT commit -- the orchestrator handles the commit after this skill returns
- Return ONLY: `{slug}: CERTIFYING`

**If the agent returns with Status still FIXING** (turn budget): read `.workflow/resolve/{slug}/fix-notes.md`, then re-invoke resolve-fix -- the fresh agent reads the notes as prior context.

**If the agent returns with Status INVESTIGATING** (circuit breaker): orchestrator re-invokes resolve-investigate.

## Handoff

Before returning, write `.workflow/resolve/{slug}/next-action.md` -- a single line:

If CERTIFYING:

```
Skill("resolve-certify", args: "{slug}")
```

If INVESTIGATING (circuit breaker):

```
Skill("resolve-investigate", args: "{slug} RE-INVESTIGATE: see fix-notes.md")
```
