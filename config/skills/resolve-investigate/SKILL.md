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

## Step 3: Reproduce Bug

Two reproduction layers:

### A. Unit/Integration Test (code-level)

Write a test that FAILS right now, proving the bug exists:
- Place it where the project's test convention expects it
- Test name should describe expected behavior, not the bug
- Run with `npm test` and confirm it FAILS
- If untestable via automated test, document WHY in diagnosis

### B. Production/Browser Reproduction

**Production Auth Discovery:**
1. Read project CLAUDE.md — look for `## Deploy` section with auth method, prod URL, and log commands.
2. Search `mcp__memory__search_nodes({ query: "production-testing" })` for supplementary auth context.
- **Local browser:** Use Playwright MCP against localhost:3001 (dev server). Works without auth.
- **Production API:** Use the discovered auth method from CLAUDE.md against the production URL.
- **Production browser:** Use discovered auth; write standalone Playwright script if browser reproduction is needed.

For local reproduction:
1. Check if dev server is running on `http://localhost:3001`. If not, start it: `npm run dev &` and wait for ready.
2. Use Playwright MCP tools to execute flows against localhost
3. Try multiple different flows until you reproduce the bug
4. Record the EXACT flow that reproduced it + evidence (console errors, visual state)

For production-only bugs (infra/proxy/timeout issues):
1. Use the discovered auth method against the production URL to test API endpoints
2. Check production logs using the log command from CLAUDE.md `## Deploy` section
3. If you cannot reproduce after thorough attempts: document what you tried and why reproduction failed

### C. Design QA Reproduction Flows (for diagnosis)

Based on what you found in A and B, design the QA flows that will become the verification contract. These will be reviewed by the user in resolve-verify before the fix begins.

- Each flow: preconditions, human-steps, expected-bug, expected-fixed
- Concrete, observable actions only
- At least 1 flow, more if bug manifests in multiple paths
- Keep flows PRACTICAL -- they will be executed by Playwright MCP, so avoid steps that require complex state setup or external dependencies

## Step 4: Classify Severity

Based on investigation results:

- **TRIVIAL (>95% confidence):** Single obvious cause (typo, wrong variable, missing import, off-by-one). Will use escape hatch.
- **STANDARD:** Clear root cause, non-trivial fix, 1-3 files affected.
- **COMPLEX:** Multiple interacting causes, race conditions, architectural issues, 4+ files.

## Step 5: Write Diagnosis

1. Read `${CLAUDE_SKILL_DIR}/diagnosis-template.md`
2. Write diagnosis to `.workflow/resolve/{slug}/diagnosis.md` using the template
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

Before returning, write `.workflow/resolve/{slug}/next-action.md` -- a single line:

If **TRIVIAL** (escape hatch succeeded):
```
TRIVIAL_COMPLETE
```

Otherwise:
```
Skill("resolve-fix", args: "{slug}")
```
