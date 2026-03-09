---
name: build
description: "Agentic feature development. Aligns with user, builds freely, certifies quality."
disable-model-invocation: true
model: opus
allowed-tools:
  - Read
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

# /build — Agentic Feature Development

Lifecycle: `DRAFTING → UNDERSTOOD → VERIFIED → BUILDING → CERTIFYING → DONE`

## Algorithm

1. Generate slug from `$ARGUMENTS` (first keyword + date, e.g., `auth-2026-02-24`)
2. If `.claude/build/{slug}/next-action.md` exists → **Read it and execute its instructions exactly**
3. If not → Read `.claude/build/{slug}/spec.md` Status and do initial routing:

| Status | Action |
|--------|--------|
| No spec / DRAFTING | `Skill("build-understand", args: "{slug} {$ARGUMENTS}")` |
| UNDERSTOOD (LITE) | Status → BUILDING, `Skill("build-implement", args: "{slug}")` |
| UNDERSTOOD (FULL) | `Skill("build-verify", args: "{slug}")` |
| VERIFIED | Status → BUILDING, `Skill("build-implement", args: "{slug}")` |
| BUILDING | `Skill("build-implement", args: "{slug}")` |
| CERTIFYING | `Skill("build-certify", args: "{slug}")` |
| DONE | Inform user, build complete |

4. After each Skill() returns → **goto step 2**

The Stop hook enforces step 2 — you cannot stop while `next-action.md` exists.

### Guardrails

- NEVER write spec content (## What, ## Acceptance Criteria, ## Edge Cases, ## Verification) yourself. Sub-skills handle all spec content.
- NEVER manually advance Status past a gate (DRAFTING→UNDERSTOOD or UNDERSTOOD→VERIFIED). Only sub-skills advance these statuses after their gates pass.
- **Empty response guard:** When ANY `AskUserQuestion` call returns an empty, blank, or whitespace-only response, it is an accidental submission. NEVER treat it as approval. Re-ask the same question immediately.
- If a sub-skill completes but Status didn't advance as expected, re-invoke the same sub-skill (max 2 retries). If still stuck, escalate to user via AskUserQuestion.
