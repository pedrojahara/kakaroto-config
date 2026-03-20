---
name: resolve
description: "Agentic bug resolution. Investigates, fixes, certifies quality."
disable-model-invocation: true
model: opus
allowed-tools:
  - Read
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
---

# /resolve -- Agentic Bug Resolution

Lifecycle: `INVESTIGATING -> DIAGNOSED -> FIXING -> CERTIFYING -> VERIFIED`

## Algorithm

**CONTINUITY RULE:** All sub-skills run forked (isolated subagents). After each Skill() returns, IMMEDIATELY proceed to the next step. NEVER output text to the user between steps. The only user-visible output is the final summary.

**ZERO questions to user.** Fully autonomous. If `$ARGUMENTS` is too vague to start, infer from recent git log, error logs, or test failures.

1. Generate slug from `$ARGUMENTS` (keyword + date, e.g., `fix-auth-2026-03-20`)

2. **RECOVERY** -- Read `.claude/resolve/{slug}/diagnosis.md` Status:
   - `VERIFIED` -> report summary, exit
   - `FAILED` -> report failure, exit
   - `CERTIFYING` -> jump to step 6
   - `FIXING` -> jump to step 5
   - `DIAGNOSED` -> jump to step 4
   - `INVESTIGATING` -> jump to step 3
   - Check for `Trivial Fix Applied: YES` -> commit, cleanup, report, exit
   - No diagnosis file -> continue to step 3

3. `Skill("resolve-investigate", args: "{slug} {$ARGUMENTS}")`
   - If return contains `TRIVIAL` -> commit with `fix: {summary}`, cleanup `.claude/resolve/{slug}/`, report, exit
   - Otherwise -> continue to step 4

4. Read diagnosis Severity and Status:
   - Edit Status -> `FIXING`
   - Continue to step 5

5. `Skill("resolve-fix", args: "{slug}")`
   - Read diagnosis Status after return:
   - If `CERTIFYING` -> continue to step 6
   - If `FIXING` (turn budget exhaustion) -> re-invoke `Skill("resolve-fix", args: "{slug}")` (max 2 total)
   - If `INVESTIGATING` (circuit breaker) -> re-invoke `Skill("resolve-investigate", args: "{slug} RE-INVESTIGATE: see fix-notes.md")` (max 1). After re-investigation, go to step 4.
   - If still stuck after retries -> Status -> `FAILED`, report, exit

6. `Skill("resolve-certify", args: "{slug}")`
   - If `VERIFIED` -> cleanup `.claude/resolve/{slug}/`, report summary
   - If `FAILED` -> report failure analysis
   - If still `CERTIFYING` -> re-invoke (max 1). If stuck -> report failure.

### Cleanup

After VERIFIED or TRIVIAL: delete `.claude/resolve/{slug}/` directory (diagnosis, fix-notes, next-action, certified marker -- all ephemeral).

### Guardrails

- NEVER write diagnosis content yourself. Sub-skills handle all diagnosis content.
- NEVER manually advance Status past `FIXING` (only sub-skills advance to CERTIFYING/VERIFIED).
- If a sub-skill completes but Status didn't advance as expected, re-invoke same sub-skill (max 2 retries).
- Track re-investigation count. Max 1 re-investigation cycle to prevent infinite loops.
