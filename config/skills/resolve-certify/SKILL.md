---
name: resolve-certify
description: "Deploy and production verification for /resolve."
user-invocable: false
model: opus
context: fork
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - ToolSearch
  - mcp__memory__search_nodes
  - mcp__memory__create_entities
  - mcp__memory__add_observations
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

# CERTIFY -- Deploy + Production QA

**Input:** `$ARGUMENTS` = `{slug}`. Diagnosis at `.workflow/resolve/{slug}/diagnosis.md` with Status: CERTIFYING.

Note: Commit was already done by the orchestrator before invoking this skill.

## Boundaries

- **Authority:** You may ONLY set Status to `VERIFIED_PROD` or `FAILED`. Never write INVESTIGATING, DIAGNOSED, VERIFIED, or FIXING.
- **Prerequisite:** Status must be CERTIFYING and code must already be committed.
- **No user interaction:** You do NOT call AskUserQuestion. When stuck, use the gate protocol (write gate-pending.md, return GATE) and the orchestrator will handle user interaction.

---

## On Invocation

1. If `.workflow/resolve/{slug}/gate-response.md` exists:
   - This is a **GATE CONTINUATION** — the user provided guidance after an escalation
   - Read `gate-response.md`
   - Delete `gate-response.md` after reading
   - Read the `step:` field from the response to determine which step was stuck
   - Jump to that step and apply the user's guidance
2. Otherwise: **fresh invocation** — start from Step 1

---

## Step 1: Pre-check

Run verify.sh as sanity check:

```bash
bash .workflow/build/verify.sh resolve-{slug}
```

If **FAIL**: This should not happen (resolve-fix should have left things passing). Investigate, fix, re-commit, and re-run. If stuck after 2 attempts, escalate via gate protocol:

- Write `.workflow/resolve/{slug}/gate-pending.md` with: what failed, error output, what you tried
- Footer: `<!-- GATE_QUESTION: verify.sh failed 2x. How should I proceed? -->` `<!-- GATE_OPTIONS: Retry with guidance | Skip pre-check | Abort -->` `<!-- GATE_STEP: 1 -->`
- Return `{slug}: GATE`

## Step 2: Quality Agents (COMPLEX only)

Read `Severity` from diagnosis.

- **TRIVIAL/STANDARD:** Skip quality agents. verify.sh (Step 1) is sufficient.
- **COMPLEX:** Read `.workflow/resolve/{slug}/fix-notes.md` for hotspots and concerns. Run sequentially:
  1. `Task(code-simplifier)` -- "Focus review on these files and concerns: {files changed + concerns from fix-notes}"
  2. `Task(code-reviewer)` -- "Focus review on these files and concerns: {files changed + concerns from fix-notes}"

If code-reviewer returns `STATUS: FAIL`: fix the identified issues, then re-run:

```bash
bash .workflow/build/verify.sh resolve-{slug}
```

Re-invoke code-reviewer. If same issues persist after 2 fix cycles, escalate via gate protocol:

- Write `.workflow/resolve/{slug}/gate-pending.md` with: code-reviewer concerns, what you tried, remaining issues
- Footer: `<!-- GATE_QUESTION: Code reviewer issues persist after 2 fix attempts. How should I proceed? -->` `<!-- GATE_OPTIONS: Fix with guidance | Accept remaining issues | Abort -->` `<!-- GATE_STEP: 2 -->`
- Return `{slug}: GATE`

## Step 2.5: Post-Quality Verification (Iron Law)

**Iron Law: "Code changed since last verification → Test again. Confidence is not evidence."**

If any quality agent modified code in Step 2 (COMPLEX only), re-verify and re-commit before deploying:

```bash
bash .workflow/build/verify.sh resolve-{slug}
```

If **FAIL**: fix the regression introduced by quality agents, re-run. Must pass before proceeding to deploy.

## Step 3: Deploy + Production QA

Run the certify script for deploy and health check:

```bash
bash .workflow/build/certify.sh resolve-{slug}
```

This script internally:

1. Re-runs verify.sh locally (V1-V3 pre-check)
2. Deploys backend (+ frontend if applicable)
3. Polls for startup + health check

If deploy is not needed (no terraform/deploy changes), use `--skip-deploy`:

```bash
bash .workflow/build/certify.sh resolve-{slug} --skip-deploy
```

If certify.sh **FAIL**: read the error output, fix the issue, re-commit if needed, re-run certify.sh. If the same approach fails twice, escalate via gate protocol:

- Write `.workflow/resolve/{slug}/gate-pending.md` with: deploy error, what you tried
- Footer: `<!-- GATE_QUESTION: Deploy failed twice. How should I proceed? -->` `<!-- GATE_OPTIONS: Fix with guidance | Skip deploy | Abort -->` `<!-- GATE_STEP: 3 -->`
- Return `{slug}: GATE`

After deploy succeeds, execute production QA verification:

**Production Auth Discovery (in order, stop at first match):**

1. **Project CLAUDE.md:** Read the project's CLAUDE.md. Look for `## Deploy` section — it contains deploy commands, production URL, auth method, and log querying instructions.
2. **Memory:** Search `mcp__memory__search_nodes({ query: "production-testing" })` for supplementary auth context.
3. **If neither found:** Skip production QA verification. Create the certified marker. Write note: "Production verification skipped — no deploy config found. Add a `## Deploy` section to project CLAUDE.md."

Steps:

1. Read the diagnosis `## QA Reproduction Flows` section
2. For API-verifiable flows: use the discovered auth method against the production URL
3. For UI-only flows: use discovered auth; write a standalone Playwright script if browser verification is needed
4. For each R1, R2...: follow human-steps, verify expected-fixed state in production
5. If any flow shows the bug still present in prod: investigate, hotfix, re-commit, re-deploy (max 2 cycles)
6. If still failing after 2 cycles, escalate via gate protocol:
   - Write `.workflow/resolve/{slug}/gate-pending.md` with: which QA flow failed, what was expected vs actual, hotfix attempts
   - Footer: `<!-- GATE_QUESTION: Production QA failed after 2 hotfix cycles. How should I proceed? -->` `<!-- GATE_OPTIONS: Fix with guidance | Accept current state | Mark as FAILED -->` `<!-- GATE_STEP: 4 -->`
   - Return `{slug}: GATE`

After all flows pass against production, create the certified marker:

```bash
mkdir -p ".workflow/resolve/{slug}"
date -u '+%Y-%m-%dT%H:%M:%SZ' > ".workflow/resolve/{slug}/certified"
```

## Step 4: Wrap Up

1. If meaningful architectural pattern or debugging insight established: `Task(memory-sync)`
2. Status -> `VERIFIED_PROD`
3. **Delete** `.workflow/resolve/{slug}/next-action.md` (resolve complete, no next step)
4. Present summary: what was broken, root cause, what was fixed, files changed, verification results (local + production), open concerns

## Output

Return ONLY: `{slug}: VERIFIED_PROD`, `{slug}: FAILED`, or `{slug}: GATE` (when escalating)
