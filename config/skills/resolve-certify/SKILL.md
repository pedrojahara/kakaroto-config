---
name: resolve-certify
description: "Quality assurance, deploy, and production verification for /resolve."
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

# CERTIFY -- Quality Assurance + Deploy + Production QA

**Input:** `$ARGUMENTS` = `{slug}`. Diagnosis at `.claude/resolve/{slug}/diagnosis.md` with Status: CERTIFYING.

## Boundaries

- **Authority:** You may ONLY set Status to `VERIFIED` or `FAILED`. Never write INVESTIGATING, DIAGNOSED, or FIXING.
- **Prerequisite:** Status must be CERTIFYING and tests must pass before proceeding.

---

## Step 1: Pre-check

Run sanity checks:
```bash
npm test -- --run
npx tsc --noEmit
npm run build
```

If **FAIL**: This should not happen (resolve-fix should have left things passing). Investigate, fix, and re-run. If stuck after 2 attempts, Status -> `FAILED`, return with failure analysis.

## Step 2: Quality Agents (STANDARD/COMPLEX only)

Read `Severity` from diagnosis.

- **TRIVIAL:** Skip quality agents (already verified in Phase 1).
- **STANDARD/COMPLEX:** Read `.claude/resolve/{slug}/fix-notes.md` for hotspots and concerns. Run sequentially:
  1. `Task(code-simplifier)` -- "Focus review on these files and concerns: {files changed + concerns from fix-notes}"
  2. `Task(code-reviewer)` -- "Focus review on these files and concerns: {files changed + concerns from fix-notes}"

If code-reviewer returns `STATUS: FAIL`: fix the identified issues, then re-run:
```bash
npm test -- --run
npx tsc --noEmit
npm run build
```
Re-invoke code-reviewer. If same issues persist after 2 fix cycles, proceed with remaining concerns documented.

## Step 3: Commit

Commit all changes with conventional commit style:
```
fix: {one-line summary from diagnosis}
```

Include all changed files (source + test).

## Step 4: Deploy + Production QA

Run the certify script for deploy and health check:
```bash
bash .claude/build/certify.sh resolve-{slug}
```

This script internally:
1. Re-runs local checks (pre-check)
2. Deploys backend (+ frontend if applicable)
3. Waits for startup + health check

If deploy is not needed (no terraform/deploy changes), use `--skip-deploy`:
```bash
bash .claude/build/certify.sh resolve-{slug} --skip-deploy
```

After deploy succeeds, execute production QA verification:
1. Read the diagnosis `## QA Reproduction Flows` section
2. Execute ALL flows with Playwright MCP tools against the **production URL**
3. For each R1, R2...: follow human-steps, verify expected-fixed state in production
4. If any flow shows the bug still present in prod: investigate, hotfix, re-commit, re-deploy (max 2 cycles)

After all flows pass against production, create the certified marker:
```bash
mkdir -p ".claude/resolve/{slug}"
date -u '+%Y-%m-%dT%H:%M:%SZ' > ".claude/resolve/{slug}/certified"
```

## Step 5: Wrap Up

1. If meaningful architectural pattern or debugging insight established: `Task(memory-sync)`
2. Status -> `VERIFIED`
3. **Delete** `.claude/resolve/{slug}/next-action.md` (resolve complete, no next step)
4. Present summary: what was broken, root cause, what was fixed, files changed, verification results (local + production), open concerns

## Output

Return ONLY: `{slug}: VERIFIED` or `{slug}: FAILED`
