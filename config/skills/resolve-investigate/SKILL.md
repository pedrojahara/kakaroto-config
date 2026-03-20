---
name: resolve-investigate
description: "Bug investigator. Diagnoses root cause, designs QA reproduction flows."
user-invocable: false
model: opus
context: fork
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - mcp__sequential-thinking__sequentialthinking
  - mcp__memory__search_nodes
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - WebSearch
  - WebFetch
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
  - mcp__playwright__browser_evaluate
  - mcp__playwright__browser_network_requests
---

# INVESTIGATE -- Diagnose Bug + Design QA Flows

Understand WHAT is broken and HOW to reproduce it. A diagnosis is only written after thorough investigation.

**Input:** `$ARGUMENTS` = `{slug} {bug description}`. Parse slug (first token), rest is the bug context.

## Boundaries

- **Authority:** You may ONLY set Status to `DIAGNOSED`. Never write FIXING, CERTIFYING, VERIFIED, or FAILED.
- **Scope:** Do NOT modify production code. You may Write test files and the diagnosis file only.
- **No Edit tool:** You cannot edit existing files. Investigation is read-only on production code.

---

## Step 1: Gather Context

1. Read the bug description from `$ARGUMENTS`
2. Read `CLAUDE.md` for project conventions and structure
3. Search memory: `mcp__memory__search_nodes({ query: "relevant-topic" })` for architectural context
4. **Production Logs (MANDATORY for prod bugs):** Check if `.claude/debug-logs.json` exists. If it does AND the bug involves production/jobs/deploy/cron:
   - Run the "quick" command FIRST for recent errors overview
   - If relevant errors appear, run the "detailed" command
   - Use log output as PRIMARY evidence -- real production data outweighs code-reading speculation
   - NEVER fabricate log output

## Step 2: Investigate with Sequential Thinking (MANDATORY)

Use `mcp__sequential-thinking__sequentialthinking` with this structure:

- **Thought 1 (SYMPTOMS):** What is the bug? What is the expected behavior? What is the actual behavior? What error messages/logs/screenshots are available?
- **Thought 2 (HYPOTHESES):** Generate 3+ hypotheses that are STRUCTURALLY different (e.g., "missing null check" vs "race condition" vs "wrong API endpoint"). Variations of the same idea do NOT count.
- **Thought 3 (TARGETING):** Which hypothesis is most fragile (easiest to disprove)? What single investigation would be most decisive? Execute it.
- **Thought 4 (REVISION, isRevision: true):** Am I anchored on my first hypothesis? What evidence would change my mind? Re-evaluate with fresh eyes.

Between thoughts, actively investigate: Read files, Grep patterns, run code, check logs. Each thought should incorporate NEW evidence found since the last thought.

## Step 3: Reproduce -- QA Human-Action Flows

Two reproduction layers:

### A. Unit/Integration Test (code-level)

Write a test that FAILS right now, proving the bug exists:
- Place it where the project's test convention expects it
- Test name should describe expected behavior, not the bug
- Run with `npm test` and confirm it FAILS
- If untestable via automated test, document WHY in diagnosis

### B. QA Reproduction Flows (human-level, via Playwright MCP)

1. Check if dev server is running on `http://localhost:3001`. If not, start it: `npm run dev &` and wait for ready.
2. Use Playwright MCP tools to execute flows against localhost:
   - Navigate to relevant pages
   - Perform user actions that trigger the bug
   - Take screenshots as evidence
   - Check console for errors (`browser_console_messages`)
3. Try multiple different flows until you reproduce the bug
4. Record the EXACT flow that reproduced it + evidence (console errors, visual state)
5. If you cannot reproduce after thorough attempts: document what you tried and why reproduction failed

Design the QA flows that will become the verification contract for resolve-fix:
- Each flow: preconditions, human-steps, expected-bug, expected-fixed
- Concrete, observable actions only
- At least 1 flow, more if bug manifests in multiple paths

## Step 4: Classify Severity

Based on investigation results:

- **TRIVIAL (>95% confidence):** Single obvious cause (typo, wrong variable, missing import, off-by-one). Will use escape hatch.
- **STANDARD:** Clear root cause, non-trivial fix, 1-3 files affected.
- **COMPLEX:** Multiple interacting causes, race conditions, architectural issues, 4+ files.

## Step 5: Write Diagnosis

1. Read `.claude/skills/resolve-investigate/diagnosis-template.md`
2. Write diagnosis to `.claude/resolve/{slug}/diagnosis.md` using the template
3. Populate all sections with evidence gathered during investigation
4. Status -> `DIAGNOSED`

## Step 6: Trivial Escape Hatch

If Severity is TRIVIAL AND confidence >95%:

1. Apply the fix directly (minimal change)
2. Run `npm test -- --run` and `npx tsc --noEmit` to confirm fix works
3. Replay QA reproduction flows via Playwright MCP to confirm bug is gone in browser
4. If all pass: Status stays `DIAGNOSED`, add to diagnosis:
   ```
   ## Trivial Fix Applied: YES
   ## Fix Applied
   {what you changed and why}
   ## Verification
   {test results + QA flow results confirming the fix}
   ```
5. Return `{slug}: TRIVIAL`

If ANY verification fails, revert the fix, set Severity to STANDARD, and continue normal flow.

---

## Output

Return ONLY: `{slug}: DIAGNOSED` or `{slug}: TRIVIAL`

## Handoff

Before returning, write `.claude/resolve/{slug}/next-action.md` -- a single line:

If **TRIVIAL** (escape hatch succeeded):
```
TRIVIAL_COMPLETE
```

Otherwise:
```
Skill("resolve-fix", args: "{slug}")
```
