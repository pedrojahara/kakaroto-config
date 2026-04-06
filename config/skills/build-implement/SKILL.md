---
name: build-implement
description: "Autonomous feature implementation from spec. Explores, challenges assumptions, builds until all tests pass."
context: fork
agent: build-implementer
user-invocable: false
model: opus
---

# IMPLEMENT — Build from Spec

You receive `{slug}` from `$ARGUMENTS`.

## Boundaries

- **Authority:** You may ONLY set Status to `CERTIFYING`. Never write UNDERSTOOD, VERIFIED, DONE, or any other status.
- **Markers:** You MUST create `v4-passed` after V4+ verification passes locally. NEVER create `certified` — that belongs to build-certify.
- **Autonomous:** No user interaction. Resolve ambiguities using the spec and the codebase.
- **Contract:** `spec.md` is truth. If spec and codebase conflict, follow the spec.

## Setup

1. Read `.workflow/build/{slug}/spec.md` — this is your contract
2. Check `Complexity` field:
   - **FULL:** proceed with steps 3-7 below
   - **LITE:** skip to Build (no exemplar study, no anti-anchoring required)
3. If the spec has `## Implementation Plan`: read it thoroughly —
   this is your execution guide (files, code, architecture, order).
   Follow as guidance. Hard constraints are `## Acceptance Criteria` only.
4. If the spec has `## Source`: read referenced file for additional context
5. Read the project's `CLAUDE.md` — these are your constraints
6. Search memory for relevant patterns: `mcp__memory__search_nodes({ query: "patterns" })`
7. Find an exemplar feature similar to this request — study its anatomy (types → service → handler → tests → UI) before writing any code

## Anti-Anchoring

**Skip if Complexity: LITE.**

Consider at least 3 implementation approaches before coding. Challenge your first instinct: what assumptions am I making? What breaks if I'm wrong? Use Sequential Thinking for complex decisions.

**Among viable approaches, prefer the simplest and most elegant solution.** Complexity must be justified — default to less code, fewer abstractions, and straightforward data flow.

## Build

If `.workflow/build/verify.sh` does not exist (LITE path — build-verify was skipped):
  Read `${CLAUDE_SKILL_DIR}/../build-verify/verify-template.md` and generate verify.sh with V1-V3 baselines only.

Freedom in HOW. Hard constraints: spec acceptance criteria, CLAUDE.md conventions, verify.sh passes.
Run `bash .workflow/build/verify.sh {slug}` frequently as feedback loop. If the same approach fails twice, reconsider via Sequential Thinking.

**verify.sh checks V1-V3 only:** unit tests, TypeScript, build.

## V4+ Verification (enforced by Stop hook)

After V1-V3 pass, you MUST execute ALL V4+ tests. The Stop hook will BLOCK you from finishing until the v4-passed marker exists.

1. Ensure dev server is running on port 3001
2. For each V4+ test in the spec's `## Verification` section: execute the steps using Playwright MCP tools against `http://localhost:3001`
3. After ALL V4+ pass, create the marker:
   ```bash
   date -u '+%Y-%m-%dT%H:%M:%SZ' > ".workflow/build/{slug}/v4-passed"
   ```

## Notes

Before signaling CERTIFYING, write `.workflow/build/{slug}/implementation-notes.md`:

- **Approach:** which of the 2+ approaches was chosen and why
- **Rejected:** what was considered and discarded (from anti-anchoring)
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
