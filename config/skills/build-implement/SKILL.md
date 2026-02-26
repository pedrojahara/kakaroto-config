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
2. If the spec has a `## Source` section, read the referenced file — these are implementation hints, not constraints
3. Read the project's `CLAUDE.md` — these are your constraints
4. Search memory for relevant patterns: `mcp__memory__search_nodes({ query: "patterns" })`
5. Find an exemplar feature similar to this request — study its anatomy (types → service → handler → tests → UI) before writing any code

## Anti-Anchoring

Consider at least 2 implementation approaches before coding. Challenge your first instinct: what assumptions am I making? What breaks if I'm wrong? Use Sequential Thinking for complex decisions.

## Build

Freedom in HOW. Hard constraints: spec acceptance criteria, CLAUDE.md conventions, verify.sh passes.
Run `bash .claude/build/verify.sh` frequently as feedback loop. If the same approach fails twice, reconsider via Sequential Thinking.

## Verify

Run ALL spec verifications with Playwright against local dev server. For each: follow the human-steps, write evidence to the specified path. verify.sh checks evidence files — fails if any is missing.

## Done

When verify.sh passes: Status → `CERTIFYING`. Return summary (<500 words): what was implemented, key decisions, files changed, test coverage, concerns for certifier.
