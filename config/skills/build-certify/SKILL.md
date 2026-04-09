---
name: build-certify
description: "Quality assurance, commit, deploy, and production verification for /build."
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

# CERTIFY — Quality Assurance + Deploy

**Input:** `$ARGUMENTS` = `{slug}`. Spec at `.workflow/build/{slug}/spec.md` with Status: CERTIFYING.

## Boundaries

- **Authority:** You may ONLY set Status to `DONE`. Never write UNDERSTOOD, VERIFIED, BUILDING, or any other status.
- **Prerequisite:** Status must be CERTIFYING and verify.sh must pass before proceeding.
- **No user interaction:** You do NOT call AskUserQuestion. When stuck, use the gate protocol (write gate-pending.md, return GATE) and the orchestrator will handle user interaction.

---

## On Invocation

1. If `.workflow/build/{slug}/gate-response.md` exists:
   - This is a **GATE CONTINUATION** — the user provided guidance after an escalation
   - Read `gate-response.md`
   - Delete `gate-response.md` after reading
   - Read the `step:` field from the response to determine which step was stuck
   - Jump to that step and apply the user's guidance
2. Otherwise: **fresh invocation** — start from Step 1

---

## Step 1: Pre-check

Run verify.sh as sanity check (V1-V3 baselines only):
```bash
bash .workflow/build/verify.sh {slug}
```

If **FAIL**: This should not happen (build-implement should have left things passing). Investigate, fix, and re-run. If stuck after 2 attempts, escalate via gate protocol:
- Write `.workflow/build/{slug}/gate-pending.md` with: what failed, error output, what you tried
- Footer: `<!-- GATE_QUESTION: verify.sh failed 2x. How should I proceed? -->` `<!-- GATE_OPTIONS: Retry with guidance | Skip pre-check | Abort build -->` `<!-- GATE_STEP: 1 -->`
- Return `{slug}: GATE`

## Step 2: Quality Agents

Read `.workflow/build/{slug}/implementation-notes.md` if it exists. Run sequentially: `Task(code-simplifier)` then `Task(code-reviewer)`. Pass to each agent: "Focus review on these files and concerns: {Hotspots + Concerns from notes}"

If code-reviewer returns `STATUS: FAIL`: fix the identified issues, then re-run all checks:
```bash
npm test -- --run
npx tsc --noEmit
npm run build
```
Re-invoke code-reviewer. If same issues persist after 2 fixes, escalate via gate protocol:
- Write `.workflow/build/{slug}/gate-pending.md` with: code-reviewer concerns, what you tried to fix, remaining issues
- Footer: `<!-- GATE_QUESTION: Code reviewer issues persist after 2 fix attempts. How should I proceed? -->` `<!-- GATE_OPTIONS: Fix with guidance | Accept remaining issues | Abort build -->` `<!-- GATE_STEP: 2 -->`
- Return `{slug}: GATE`

## Step 3: Commit

Commit all changes (conventional commits style).

## Step 4: Deploy + Production Verification

**This step has TWO hard gates enforced by bash scripts. Both markers must exist for DONE.**

### 4a. Deploy via certify.sh

Run the certify script for deploy and health check:
```bash
bash .workflow/build/certify.sh {slug}
```

This script internally:
1. Re-runs verify.sh locally (V1-V3 pre-check)
2. Deploys backend (+ frontend if applicable)
3. Waits for startup + health check
4. **Creates the `certified` marker** — proof that deploy succeeded

If deploy is not needed (no terraform/deploy.sh), use `--skip-deploy`:
```bash
bash .workflow/build/certify.sh {slug} --skip-deploy
```

If certify.sh **FAIL**: read the error output, fix the issue, re-commit if needed, re-run certify.sh. If the same approach fails twice, escalate via gate protocol:
- Write `.workflow/build/{slug}/gate-pending.md` with: deploy error, what you tried
- Footer: `<!-- GATE_QUESTION: Deploy failed twice. How should I proceed? -->` `<!-- GATE_OPTIONS: Fix with guidance | Skip deploy | Abort build -->` `<!-- GATE_STEP: 4 -->`
- Return `{slug}: GATE`

### 4b. Production V4+ verification

**Production Auth Discovery (in order, stop at first match):**
1. **Project CLAUDE.md:** Read the project's CLAUDE.md. Look for `## Deploy` section — it contains deploy commands, production URL, auth method, and log querying instructions.
2. **Memory:** Search `mcp__memory__search_nodes({ query: "production-testing" })` for supplementary auth context.
3. **If neither found:** Skip production V4+ verification. Write to implementation-notes.md: "Production verification skipped — no deploy config found. Add a `## Deploy` section to project CLAUDE.md." Create v4-passed marker and proceed to Step 5.

After certify.sh succeeds (the `certified` marker now exists):
1. Delete the implement-phase v4-passed marker to ensure fresh production verification:
   ```bash
   rm -f ".workflow/build/{slug}/v4-passed"
   ```
2. Read the spec's `## Verification` section
3. For API-verifiable flows: use the discovered auth method against the production URL
4. For UI-only flows: use discovered auth; write a standalone Playwright script if browser verification is needed
5. Verify expected results

### 4c. Final gate

After all V4+ pass, create the V4 marker and run the final gate:
```bash
date -u '+%Y-%m-%dT%H:%M:%SZ' > ".workflow/build/{slug}/v4-passed"
bash .workflow/build/verify.sh {slug} --full
```

**`verify.sh --full` requires BOTH markers:**
- `certified` — created by certify.sh (bash), proves deploy ran
- `v4-passed` — created by you after V4+ verification

If either marker is missing, verify.sh will FAIL — blocking DONE. NEVER create the `certified` marker yourself; only certify.sh creates it.

## Step 5: Wrap Up

1. If meaningful architectural patterns established: `Task(memory-sync)`
2. Status -> `DONE`
3. **Delete** `.workflow/build/{slug}/next-action.md` (build complete, no next step)
4. Present summary: what was built, files changed (`git diff --stat`), test coverage, production verification results, open concerns

## Output

Return ONLY: `{slug}: DONE` or `{slug}: GATE` (when escalating). No summaries, no explanations. After deleting next-action.md and setting Status DONE, the build is complete.
