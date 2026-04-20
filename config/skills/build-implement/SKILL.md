---
name: build-implement
description: "Autonomous feature implementation from spec. Explores, challenges assumptions, builds until all tests pass."
context: fork
agent: build-implementer
user-invocable: false
model: opus
effort: xhigh
---

# IMPLEMENT — Build from Spec

You receive `{slug}` from `$ARGUMENTS`.

## Boundaries

- **Authority:** You may ONLY set Status to `CERTIFYING`. Never write UNDERSTOOD, DONE, or any other status.
- **Markers:** You MUST create `v4-passed` after V4+ verification passes locally (or immediately if no V4+ tests exist). NEVER create `certified` — that belongs to build-certify.
- **Autonomous:** No user interaction. Resolve ambiguities using the spec and the codebase.
- **Contract:** `spec.md` is truth. If spec and codebase conflict, follow the spec.

## Setup

1. Read `.workflow/build/{slug}/spec.md` — this is your contract
2. Read the `Complexity` field — this determines verification depth:
   - `TRIVIAL`: minimal ceremony, V1-V3 only, no anti-anchoring
   - `STANDARD`: normal implementation, V1-V3 only
   - `COMPLEX`: full implementation with anti-anchoring and V4+ if `## Verification` exists
3. If the spec has `## Implementation Plan`: read it thoroughly —
   this is your execution guide (files, code, architecture, order).
   Follow as guidance. Hard constraints are `## Acceptance Criteria` only.
4. If the spec has `## Source` containing a `.md` file path: read the original plan file in FULL.
   The plan has code snippets, parameters, architecture decisions.
   **When spec and plan conflict, plan wins** (written by user).
   When plan references code that no longer exists, trust current codebase.
   **Codebase invariant check:** if the plan directs a change that violates a convention stated in CLAUDE.md, an existing architectural pattern, or a declared constraint (security / data-integrity / cross-module API contract), do NOT silently comply. Record the conflict as a `## Concerns` bullet in `implementation-notes.md`, implement the spec's acceptance criteria using the convention-respecting approach, and surface the conflict explicitly so code-reviewer catches it in build-certify. Do NOT escalate to user at this stage — the handoff is via notes; the user sees the surfaced concern at certify time.
5. Read the project's `CLAUDE.md` — these are your constraints
6. Search memory for relevant patterns: `mcp__memory__search_nodes({ query: "patterns" })`
7. **(Skip if spec has `## Source`.)** Find an exemplar feature similar to this request — study its anatomy (types → service → handler → tests → UI) before writing any code

## Anti-Anchoring

**Skip for TRIVIAL complexity.**

- If spec has `## Source` (plan file): implement the plan directly. Anti-anchoring activates only if verify.sh fails 3 times on the same area.
- Otherwise: consider at least 3 implementation approaches before coding. Challenge your first instinct: what assumptions am I making? What breaks if I'm wrong? Use Sequential Thinking for complex decisions.

**Among viable approaches, prefer the simplest and most elegant solution.** Default to less code, fewer abstractions, and straightforward data flow.

## Build

Read `${CLAUDE_SKILL_DIR}/verify-template.md` and generate `.workflow/build/verify.sh` with V1-V3 baselines.

Freedom in HOW. Hard constraints: spec acceptance criteria, CLAUDE.md conventions, verify.sh passes.
Run `bash .workflow/build/verify.sh {slug}` frequently as feedback loop. If the same approach fails twice, reconsider via Sequential Thinking.

**Tests are mandatory.** New functionality MUST have tests — this is enforced by CLAUDE.md ("Código sem teste = PR rejeitado"). Write tests as part of implementation, not as an afterthought. Exceptions: config files, .d.ts, UI-only without logic.

**verify.sh checks V1-V3 only:** unit tests, TypeScript, build.

## V4+ Verification (enforced by Stop hook)

After V1-V3 pass, check whether V4+ tests exist in the spec:

### If spec has `## Verification` section with V4+ tests:

Execute ALL V4+ tests. The Stop hook will BLOCK you from finishing until the v4-passed marker exists.

1. Ensure dev server is running on port 3001
2. For each V4+ test in the spec's `## Verification` section:
   a. Execute the **steps** using Playwright MCP tools against `http://localhost:3001`
   b. After completing all steps, execute the **checks** (if present):
   - `console: no-errors` → `browser_console_messages()` → fail if any error-level entries
   - `url: contains "X"` → `browser_evaluate({ script: "location.href.includes('X')" })` → fail if false
   - `text: visible "X"` → `browser_evaluate({ script: "document.body.innerText.includes('X')" })` → fail if false
   - `text: not-visible "X"` → `browser_evaluate({ script: "!document.body.innerText.includes('X')" })` → fail if false
   - `state: no-loading` → `browser_evaluate({ script: "!document.querySelector('.spinner, .loading, [aria-busy=\"true\"]')" })` → fail if false
     c. If ANY check fails → the V4+ flow FAILS, even if your prose interpretation said it looked correct. Fix the issue and re-run.
3. After ALL V4+ pass (steps + checks), create the marker:
   ```bash
   date -u '+%Y-%m-%dT%H:%M:%SZ' > ".workflow/build/{slug}/v4-passed"
   ```

### If spec has NO `## Verification` section:

V1-V3 passing is sufficient. Create the marker immediately:

```bash
date -u '+%Y-%m-%dT%H:%M:%SZ' > ".workflow/build/{slug}/v4-passed"
```

## Notes

Before signaling CERTIFYING, write `.workflow/build/{slug}/implementation-notes.md`:

- **Approach:** which of the 2+ approaches was chosen and why (skip for TRIVIAL)
- **Rejected:** what was considered and discarded (skip for TRIVIAL)
- **Changed:** files list (new | modified), 1-line rationale each
- **Concerns:** low-confidence areas, debt introduced, edge cases deferred
- **Hotspots:** files/functions where reviewer should focus hardest

## Done

When `bash .workflow/build/verify.sh {slug} --full` passes (V1-V3 + V4+): Status → `CERTIFYING`, implementation-notes.md written.

Return ONLY: `{slug}: CERTIFYING`

**If the agent returns with Status still BUILDING** (turn budget exhaustion): read `.workflow/build/{slug}/implementation-notes.md`, then re-invoke `build-implement` — the fresh agent reads the notes as prior context.

## Handoff

Before returning, write `.workflow/build/{slug}/next-action.md` — a single line:

```
Skill("build-certify", args: "{slug}")
```
