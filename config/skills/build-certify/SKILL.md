---
name: build-certify
description: "Quality assurance, commit, deploy, and production verification for /build."
user-invocable: false
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
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

**Input:** `$ARGUMENTS` = `{slug}`. Spec at `.claude/build/{slug}/spec.md` with Status: CERTIFYING.

## Boundaries

- **Authority:** You may ONLY set Status to `DONE`. Never write UNDERSTOOD, VERIFIED, BUILDING, or any other status.
- **Prerequisite:** Status must be CERTIFYING and verify.sh must pass before proceeding.

---

## Step 1: Pre-check

Run verify.sh as sanity check (V1-V3 baselines only):
```bash
bash .claude/build/verify.sh {slug}
```

If **FAIL**: This should not happen (build-implement should have left things passing). Investigate, fix, and re-run. If stuck after 2 attempts, escalate to user via AskUserQuestion. **Empty response guard:** If the user's response is empty or blank, re-ask — never treat empty as confirmation.

## Step 2: Quality Agents

Read `Complexity` from spec.

- **FULL:** Read `.claude/build/{slug}/implementation-notes.md` if it exists. Run sequentially: `Task(code-simplifier)` then `Task(code-reviewer)`. Pass to each agent: "Focus review on these files and concerns: {Hotspots + Concerns from notes}"
- **LITE:** Skip quality agents. verify.sh (Step 1) is sufficient for single-pattern changes.

**FULL path details (when running quality agents):**

If code-reviewer returns `STATUS: FAIL`: fix the identified issues, then re-run all checks:
```bash
npm test -- --run
npx tsc --noEmit
npm run build
```
Re-invoke code-reviewer. If same issues persist after 2 fixes, escalate remaining concerns to user via `AskUserQuestion`.

## Step 3: Commit

Commit all changes (conventional commits style).

## Step 4: Deploy + Production Verification

Run the certify script for deploy and health check:
```bash
bash .claude/build/certify.sh {slug}
```

This script internally:
1. Re-runs verify.sh locally (V1-V3 pre-check)
2. Deploys backend (+ frontend if applicable)
3. Waits for startup + health check

If deploy is not needed (no terraform/deploy.sh), use `--skip-deploy`:
```bash
bash .claude/build/certify.sh {slug} --skip-deploy
```

After deploy succeeds (or with --skip-deploy), execute production verification:
1. Read the spec's `## Verification` section
2. Execute all V4+ human-action flows with Playwright MCP tools against the production URL
3. Verify expected results are visible on screen

If certify.sh **FAIL**: read the error output, fix the issue, re-commit if needed, re-run certify.sh. If the same approach fails twice, try a different approach. Only escalate to user when genuinely stuck.

After all V4+ pass against production, create the certified marker:
```bash
mkdir -p ".claude/build/{slug}"
date -u '+%Y-%m-%dT%H:%M:%SZ' > ".claude/build/{slug}/certified"
```

## Step 5: Wrap Up

1. If meaningful architectural patterns established: `Task(memory-sync)`
2. Status -> `DONE`
3. **Delete** `.claude/build/{slug}/next-action.md` (build complete, no next step)
4. Present summary: what was built, files changed (`git diff --stat`), test coverage, production verification results, open concerns

## Output

Return summary. After deleting next-action.md and setting Status DONE, the build is complete.
