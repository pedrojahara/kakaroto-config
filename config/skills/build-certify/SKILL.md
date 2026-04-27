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

- **Authority:** You may ONLY set Status to `DONE`. Never write UNDERSTOOD, BUILDING, or any other status.
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

Read `Complexity` from spec. Security and correctness are binary — complexity doesn't change the bar. Clarity polish can scale with scope.

- **TRIVIAL:** verify.sh (Step 1) is sufficient by default. Proceed to Step 3.
  **Run `Task(code-reviewer)` anyway when the diff touches security-sensitive code.** Detection: `git diff | grep -Ei 'auth|session|permission|role|sql|query|crypto|sign|token|secret|sanitize|exec|eval|child_process'`. Any hit → run code-reviewer with "Spec path: `.workflow/build/{slug}/spec.md`. TRIVIAL security trigger — review the diff for injection, auth bypass, token leakage, or unsafe deserialization." Handle FAIL per the standard flow below.
- **STANDARD:** Run ONLY `Task(code-reviewer)` for correctness/security/acceptance-criteria check. Skip code-simplifier (not worth the turn cost at this scope). Pass: "Spec path: `.workflow/build/{slug}/spec.md`. Review diff for security, bugs, typing, and spec acceptance criteria gaps."
- **COMPLEX:** Read `.workflow/build/{slug}/implementation-notes.md` if it exists. Run sequentially: `Task(code-reviewer)` FIRST (security/bugs/spec acceptance), then `Task(code-simplifier)` (clarity polish on corrected code). This order prevents simplifier from refactoring code the reviewer is about to rewrite. Pass to each agent: "Spec path: `.workflow/build/{slug}/spec.md`. Focus review on these files and concerns: {Hotspots + Concerns from notes}."

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

## Step 2.5: Post-Quality Verification (Iron Law)

**Iron Law: "Code changed since last verification → Test again. Confidence is not evidence."**

If any quality agent modified code in Step 2, re-verify before committing:
```bash
bash .workflow/build/verify.sh {slug}
```

If **FAIL**: fix the regression introduced by quality agents, re-run. Must pass before proceeding to commit.

## Step 3: Commit

Commit all changes (conventional commits style).

## Step 3.5: Drift Check (pre-deploy)

Before calling certify.sh, scan `implementation-notes.md` for imperative infra commands that may have been applied only to dev:

```bash
notes=".workflow/build/{slug}/implementation-notes.md"
[ -f "$notes" ] && grep -nE '\b(gcloud|gsutil|firebase deploy|aws s3|aws iam|kubectl apply|curl -X (POST|PUT|DELETE))\b' "$notes" || true
```

For each match: read the surrounding line. Skip matches that are inside code comments, docs, or obviously scoped to local-only dev setup (e.g. `gcloud auth login`, `gcloud config set project`).

If any match looks like a **mutation of shared infra** (bucket CORS/IAM/lifecycle, IAM binding, Firestore index deploy, Secret Manager put, Cloud Run env var), write `.workflow/build/{slug}/gate-pending.md`:

- Body: list each imperative command with file path + line number. Include the notes context verbatim.
- Footer:
  - `<!-- GATE_QUESTION: {command} was run during implementation. Was it also applied to production? -->`
  - `<!-- GATE_OPTIONS: Yes, applied to prod (proceed) | No, dev only — block and fix | Move to Terraform now -->`
  - `<!-- GATE_STEP: 3.5 -->`
- Return `{slug}: GATE`.

If the user answers "Yes, applied to prod (proceed)": record the confirmation in notes and proceed to Step 4. If "No": block with a clear error — do NOT call certify.sh. If "Move to Terraform now": treat as fix-and-retry; user will ask you to edit terraform/*.tf in a follow-up turn.

No matches → proceed.

## Step 4: Deploy + Production Verification (single gate)

Run the certify script. This is the **only** gate that writes the `certified` marker — it does deploy, `/health` precondition, and production V4+ verification as one atomic pipeline:

```bash
bash .workflow/build/certify.sh {slug}
```

`certify.sh` runs, in order:

1. Re-runs verify.sh locally (V1-V3)
2. Deploys backend (+ frontend if applicable)
3. Polls `/health` until service responds (precondition — "is the service up?", NOT the QA gate)
4. Resolves `PROD_URL=$(cd terraform/frontend && terraform output -raw frontend_url)`
5. Loads `E2E_TEST_EMAIL` / `E2E_TEST_PASSWORD` from `.env` (if present)
6. Deletes the implement-phase `v4-passed` marker
7. Runs `BASE_URL=$PROD_URL node .workflow/build/{slug}/v4-runner.mjs`
8. On success: writes fresh `v4-passed` (prod timestamp) AND `certified`
9. On failure at ANY step: exits non-zero without writing markers

If spec has no `## Verification` or marks `Verification-Mode: local-only`, steps 4-7 are skipped (runner is not invoked) — `certified` is written right after `/health`.

If deploy is not needed (no `terraform/deploy.sh`), use `--skip-deploy`:
```bash
bash .workflow/build/certify.sh {slug} --skip-deploy
```

If certify.sh **FAIL**: read the error output — the script tells you exactly which stage failed. Fix the issue, re-commit if needed, re-run certify.sh. If the same approach fails twice, escalate via gate protocol:
- Write `.workflow/build/{slug}/gate-pending.md` with: stage that failed, error output, what you tried
- Footer: `<!-- GATE_QUESTION: certify.sh failed twice at stage {X}. How should I proceed? -->` `<!-- GATE_OPTIONS: Fix with guidance | Skip deploy | Abort build -->` `<!-- GATE_STEP: 4 -->`
- Return `{slug}: GATE`

**Hard rule:** NEVER hand-touch `certified` or `v4-passed`. Only `certify.sh` writes them. If a marker is missing, the pipeline is telling you prod is broken.

### 4b. Final audit

After certify.sh succeeds, run the final audit:
```bash
bash .workflow/build/verify.sh {slug} --full
```

**`verify.sh --full` requires:**
- `v4-runner.mjs` exists (spec has `## Verification` → runner is a mandatory artifact)
- `certified` marker exists (proves full pipeline, including prod V4+, succeeded)
- `v4-passed` marker exists (fresh prod timestamp from certify.sh, or local-only if opted out)

If this fails, do NOT set Status to DONE — certify.sh lied about success or artifacts drifted.

## Step 5: Wrap Up

1. If meaningful architectural patterns established: `Task(memory-sync)`
2. Status -> `DONE`
3. **Delete** `.workflow/build/{slug}/next-action.md` (build complete, no next step)
4. Present summary: what was built, files changed (`git diff --stat`), test coverage, production verification results, open concerns

## Output

Return ONLY: `{slug}: DONE` or `{slug}: GATE` (when escalating). No summaries, no explanations. After deleting next-action.md and setting Status DONE, the build is complete.
