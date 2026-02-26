---
name: build
description: "Agentic feature development. Aligns with user, builds freely, certifies quality."
disable-model-invocation: true
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - Skill
  - AskUserQuestion
  - mcp__memory__search_nodes
  - mcp__memory__create_entities
  - mcp__memory__add_observations
  - mcp__sequential-thinking__sequentialthinking
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
---

# /build — Agentic Feature Development

Three phases, each with isolated context. A spec file is the single boundary object.

Lifecycle: `DRAFTING → UNDERSTOOD → VERIFIED → BUILDING → CERTIFYING → DONE`

## Phase Routing

1. Generate slug: first keyword from `$ARGUMENTS` + date (e.g., `auth-2026-02-24`)
2. Check `.claude/build/{slug}/spec.md`
3. Route based on spec Status field:

| Condition | Action |
|-----------|--------|
| No spec OR Status: DRAFTING | `Skill("build-understand", args: "{slug} {$ARGUMENTS}")` |
| Status: UNDERSTOOD | `Skill("build-verify", args: "{slug}")` |
| Status: VERIFIED | Assert verify.sh exists, Status → BUILDING, route to build-implement (see below) |
| Status: BUILDING | `Skill("build-implement", args: "{slug}")` |
| Status: CERTIFYING | Execute Phase 3 below |
| Status: DONE | Inform user, offer `/ship` |

### VERIFIED Handler (inline)

When Status is `VERIFIED`:
1. Assert `.claude/build/verify.sh` exists (build-verify generates it).
   If missing, error: re-invoke `Skill("build-verify", args: "{slug}")`.
2. Update Status → `BUILDING`
3. Re-read Status and route per Phase Routing table

After any Skill returns:
1. Re-read `.claude/build/{slug}/spec.md` Status field
2. Route according to the Phase Routing table above

Never assume the next phase — always check Status.

### Guardrails

- NEVER write spec content (## What, ## Acceptance Criteria, ## Edge Cases, ## Verification) yourself. Sub-skills handle all spec content.
- NEVER manually advance Status past a gate (DRAFTING→UNDERSTOOD or UNDERSTOOD→VERIFIED). Only sub-skills advance these statuses after their gates pass.
- If a sub-skill completes but Status didn't advance as expected, re-invoke the same sub-skill (max 2 retries). If still stuck, escalate to user via AskUserQuestion.

---

## Phase 3: CERTIFY

Runs inline (no context fork — needs full state).

### 3.1 Quality Agents

Run sequentially: `Task(code-simplifier)` → `Task(code-reviewer)`.

If code-reviewer returns `STATUS: FAIL`: fix the identified issues, then re-run all checks:
```bash
npm test -- --run
npx tsc --noEmit
npm run build
```
Re-invoke code-reviewer. If same issues persist after 2 fixes, escalate remaining concerns to user via `AskUserQuestion`.

### 3.2 Deploy

1. Commit (conventional commits style)
2. `Skill("ship")` to deploy

### 3.3 Production Verification

Run ALL spec verifications with Playwright against the **PRODUCTION URL**. For each: follow the human-steps from spec's `## Verification`, write evidence to the specified path.

If a verification fails, fix and re-deploy. If the same approach fails twice, try a different approach. Only escalate to user when genuinely stuck.

### 3.4 Wrap Up

1. If meaningful architectural patterns established → `Task(memory-sync)`
2. Status → `DONE`
3. Present summary: what was built, files changed (`git diff --stat`), test coverage, production verification results, open concerns
