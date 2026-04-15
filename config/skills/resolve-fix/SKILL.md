---
name: resolve-fix
description: "Autonomous bug fixer. Fixes root cause, verifies via tests and QA flows."
context: fork
agent: resolve-fixer
user-invocable: false
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - mcp__sequential-thinking__sequentialthinking
  - mcp__memory__search_nodes
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
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
  - mcp__playwright__browser_hover
  - mcp__playwright__browser_select_option
  - mcp__playwright__browser_evaluate
  - mcp__playwright__browser_network_requests
  - mcp__playwright__browser_navigate_back
---

# FIX -- Resolve Root Cause + Local QA Verification

You receive `{slug}` from `$ARGUMENTS`.

## Boundaries

- **Authority:** You may ONLY set Status to `CERTIFYING` or `INVESTIGATING` (circuit breaker). Never write DIAGNOSED, VERIFIED, DONE, or FAILED.
- **Autonomous:** No user interaction. Resolve ambiguities using the diagnosis and the codebase.
- **Contract:** `diagnosis.md` is truth. The root cause and QA flows are your guide.

## Setup

1. **Gate continuation check:** if `.workflow/resolve/{slug}/gate-response.md` exists, read it, delete it, parse the `selected:` and `step:` fields. If `step: scope-lock`, resume the Scope Lock decision with the user's choice (proceed with Edit, widen scope, or abort).
2. Read `.workflow/resolve/{slug}/diagnosis.md` -- this is your contract (WHAT is broken + HOW to verify)
3. Read the project's `CLAUDE.md` -- constraints and conventions
4. Search memory if relevant: `mcp__memory__search_nodes({ query: "relevant-pattern" })`
5. Read the Root Cause, Suggested Fix, Hotspots, and QA Reproduction Flows sections

## Scope Lock

Before the first Edit, read `.workflow/resolve/{slug}/scope.txt` (written by resolve-investigate Phase A). Parse lines:

- `allow-dir: {path}` — directory prefix
- `allow-file: {path}` — exact file path
- `allow-glob: {pattern}` — glob pattern
- `#` or blank lines — ignored (comments)

For each Edit target, check in order:

1. Target path equals any `allow-file` → proceed
2. Target path starts with any `allow-dir` → proceed
3. Target path matches any `allow-glob` → proceed
4. Target is a `Write` of a NEW file (not Edit of existing) → proceed (creation is exempt)
5. Otherwise → **gate pattern**: write `.workflow/resolve/{slug}/gate-pending.md`:

   ```markdown
   Fix needs to edit `{path}`, which is outside the declared scope:

   {list of allow-dir/allow-file/allow-glob entries}

   <!-- GATE_QUESTION: Fix needs to edit {path}, outside declared scope. Allow? -->
   <!-- GATE_OPTIONS: Allow once | Widen scope permanently | Abort -->
   <!-- GATE_STEP: scope-lock -->
   ```

   Return `{slug}: GATE`. The orchestrator handles `AskUserQuestion` and re-invokes you with `gate-response.md`.

On gate-response:

- `Allow once` → proceed with the Edit, do not modify scope.txt
- `Widen scope permanently` → append `allow-file: {path}` to scope.txt, proceed
- `Abort` → update diagnosis Status to `INVESTIGATING`, write `fix-notes.md` with the rejected path, return `{slug}: RE-INVESTIGATE`

If `scope.txt` does not exist (legacy diagnosis without scope lock): proceed without enforcement but log a warning comment in `fix-notes.md`.

## Fix

Make the **minimum change** that fixes the root cause. After each change:

```bash
npm test -- --run
npx tsc --noEmit
```

If the same approach fails twice, use Sequential Thinking to reconsider.

## Local QA Verification

After unit tests pass, execute ALL QA Reproduction Flows from the diagnosis:

**Auth Discovery:** Read project CLAUDE.md `## Deploy` section for auth method and prod URL. Also search `mcp__memory__search_nodes({ query: "production-testing" })`.

- **Local browser:** Playwright MCP against `http://localhost:3001` (no auth needed in dev)
- **API testing:** Use the discovered auth method from CLAUDE.md
- **Production-only bugs:** If the bug only manifests in production, use discovered auth against the production URL. Check logs using the log command from CLAUDE.md `## Deploy` section.

Steps:

1. For browser-testable flows: ensure dev server is running, use Playwright MCP against localhost
2. For API-testable flows: use curl with appropriate auth
3. For each R1, R2...: follow human-steps exactly
4. Verify expected-fixed state
5. If the flow has `checks:`, execute them as deterministic assertions:
   - `console: no-errors` → `browser_console_messages()` → fail if any error-level entries
   - `url: contains "X"` → `browser_evaluate({ script: "location.href.includes('X')" })` → fail if false
   - `text: visible "X"` → `browser_evaluate({ script: "document.body.innerText.includes('X')" })` → fail if false
   - `text: not-visible "X"` → `browser_evaluate({ script: "!document.body.innerText.includes('X')" })` → fail if false
   - `state: no-loading` → `browser_evaluate({ script: "!document.querySelector('.spinner, .loading, [aria-busy=\"true\"]')" })` → fail if false
6. If any flow or check still shows the bug: fix is incomplete, iterate

## Circuit Breaker

Attempt 4 with no progress -> Update diagnosis Status -> `INVESTIGATING`. Write findings to fix-notes.md. Return `{slug}: RE-INVESTIGATE`. The orchestrator will re-invoke resolve-investigate with new context.

## Notes

Before signaling CERTIFYING, write `.workflow/resolve/{slug}/fix-notes.md`:

- Approach chosen and why
- Rejected approaches
- Files changed with rationale
- QA verification results per flow
- Concerns and low-confidence areas

## Done

When `npm test -- --run` passes AND `npx tsc --noEmit` passes AND all QA flows pass via Playwright MCP:

- Status -> `CERTIFYING`
- fix-notes.md written
- Do NOT commit -- the orchestrator handles the commit after this skill returns
- Return ONLY: `{slug}: CERTIFYING`

**Return values:**

- `{slug}: CERTIFYING` — fix applied, local QA passed
- `{slug}: RE-INVESTIGATE` — circuit breaker triggered, re-investigate needed
- `{slug}: GATE` — scope lock hit, orchestrator handles via gate pattern

**If the agent returns with Status still FIXING** (turn budget): read `.workflow/resolve/{slug}/fix-notes.md`, then re-invoke resolve-fix -- the fresh agent reads the notes as prior context.

**If the agent returns with Status INVESTIGATING** (circuit breaker): orchestrator re-invokes resolve-investigate.

**If the agent returns `{slug}: GATE`** (scope lock): orchestrator reads `gate-pending.md`, calls `AskUserQuestion`, writes `gate-response.md`, re-invokes resolve-fix. The fresh agent detects `gate-response.md` on startup and resumes where the scope lock was raised.

## Handoff

Before returning, write `.workflow/resolve/{slug}/next-action.md` -- a single line:

If CERTIFYING:

```
Skill("resolve-certify", args: "{slug}")
```

If INVESTIGATING (circuit breaker):

```
Skill("resolve-investigate", args: "{slug} PHASE_D: RE-INVESTIGATE from fix-notes.md")
```
