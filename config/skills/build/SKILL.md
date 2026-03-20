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

**CONTINUITY RULE:** All sub-skills run forked (isolated subagents). After each Skill() returns, IMMEDIATELY proceed to the next step. NEVER output text to the user between steps. The only user-visible output is the final DONE summary.

1. Generate slug from `$ARGUMENTS` (first keyword + date, e.g., `auth-2026-02-24`)

2. **RECOVERY** — Read `.claude/build/{slug}/spec.md` Status:
   - `BUILDING` → jump to step 6
   - `CERTIFYING` → jump to step 7
   - `DONE` → inform user, exit
   - `UNDERSTOOD` → check Complexity: FULL → jump to step 4, LITE → jump to step 5
   - `VERIFIED` → jump to step 5
   - Otherwise (no spec / DRAFTING) → continue to step 3

3. `Skill("build-understand", args: "{slug} {$ARGUMENTS}")`
   — If return contains `CANCELLED` → inform user "Build cancelled — feature already solved or not needed", exit.
   — Otherwise: read `.claude/build/{slug}/spec.md` Complexity. FULL → step 4, LITE → step 5.

4. Read spec Complexity:
   - **FULL** → `Skill("build-verify", args: "{slug}")`
     — After return: proceed to step 5.
   - **LITE** → continue to step 5.

5. Edit spec Status → `BUILDING`
   `Skill("build-implement", args: "{slug}")`
   — After return: proceed to step 6.
   If Status still BUILDING after return: re-invoke (max 2). If stuck → AskUserQuestion.

6. Read spec Status. If CERTIFYING → proceed. If BUILDING → jump to step 5 (max 2 total retries).
   `Skill("build-certify", args: "{slug}")`
   — If DONE → exit. If CERTIFYING → re-invoke (max 1). If stuck → AskUserQuestion.

7. `Skill("build-certify", args: "{slug}")`
   — Recovery entry for CERTIFYING. Same as step 6.

### Guardrails

- NEVER write spec content (## What, ## Acceptance Criteria, ## Edge Cases, ## Verification) yourself. Sub-skills handle all spec content.
- NEVER manually advance Status past a gate (DRAFTING→UNDERSTOOD or UNDERSTOOD→VERIFIED). Only sub-skills advance these statuses after their gates pass.
- **Empty response guard:** When ANY `AskUserQuestion` call returns an empty, blank, or whitespace-only response, it is an accidental submission. NEVER treat it as approval. Re-ask the same question immediately.
- If a sub-skill completes but Status didn't advance as expected, re-invoke the same sub-skill (max 2 retries). If still stuck, escalate to user via AskUserQuestion.
