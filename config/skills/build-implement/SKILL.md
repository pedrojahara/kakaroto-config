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
- **Autonomous:** No user interaction. Resolve ambiguities using the spec and the codebase.
- **Contract:** `spec.md` is truth. If spec and codebase conflict, follow the spec.

## Setup

1. Read `.claude/build/{slug}/spec.md` — this is your contract (WHAT to build + HOW to verify)
2. Check `Complexity` field:
   - **FULL:** proceed with steps 3-5 below
   - **LITE:** skip to Build (no exemplar study, no anti-anchoring required)
3. If the spec has a `## Source` section, read the referenced file — these are implementation hints, not constraints
4. Read the project's `CLAUDE.md` — these are your constraints
5. Search memory for relevant patterns: `mcp__memory__search_nodes({ query: "patterns" })`
6. Find an exemplar feature similar to this request — study its anatomy (types → service → handler → tests → UI) before writing any code

## Anti-Anchoring

**Skip if Complexity: LITE.**

Consider at least 2 implementation approaches before coding. Challenge your first instinct: what assumptions am I making? What breaks if I'm wrong? Use Sequential Thinking for complex decisions.

## Build

If `.claude/build/verify.sh` does not exist (LITE path — build-verify was skipped):
  Read `.claude/skills/build-verify/verify-template.md` and generate verify.sh with V1-V3 baselines only.

Freedom in HOW. Hard constraints: spec acceptance criteria, CLAUDE.md conventions, verify.sh passes.
Run `bash .claude/build/verify.sh {slug}` frequently as feedback loop. If the same approach fails twice, reconsider via Sequential Thinking.

**verify.sh checks V1-V3 only:** unit tests, TypeScript, build.

## Verify

After implementation, execute all V4+ verifications from the spec's `## Verification` section using Playwright MCP tools against the local dev server (`http://localhost:3001`). For each V4+: follow the human-steps, verify expected results are visible on screen.

## Notes

Before signaling CERTIFYING, write `.claude/build/{slug}/implementation-notes.md`:

- **Approach:** which of the 2+ approaches was chosen and why
- **Rejected:** what was considered and discarded (from anti-anchoring)
- **Changed:** files list (new | modified), 1-line rationale each
- **Concerns:** low-confidence areas, debt introduced, edge cases deferred
- **Hotspots:** files/functions where reviewer should focus hardest

## Done

When `bash .claude/build/verify.sh {slug}` passes (V1-V3) AND all V4+ verifications pass via MCP: Status → `CERTIFYING`, implementation-notes.md written. Return summary (<500 words): what was implemented, key decisions, files changed, test coverage, concerns for certifier.

**If the agent returns with Status still BUILDING** (turn budget exhaustion): read `.claude/build/{slug}/implementation-notes.md`, then re-invoke `build-implement` — the fresh agent reads the notes as prior context.

## Handoff

Before returning, write `.claude/build/{slug}/next-action.md`:

```
## Context
build-implement complete. All verifications passing. Status: CERTIFYING.

## Action
1. Run `bash .claude/build/verify.sh {slug}` as pre-check
2. If PASS: Call `Skill("build-certify", args: "{slug}")`
3. If FAIL: Update Status to BUILDING, call `Skill("build-implement", args: "{slug}")`
```
