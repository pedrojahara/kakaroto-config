---
name: build-implement
description: "Autonomous feature implementation from spec. Builds until all tests pass."
context: fork
agent: build-implementer
user-invocable: false
---

# Phase 2: IMPLEMENT

You receive `{slug}` from `$ARGUMENTS`.

## Setup

1. Read `.claude/build/{slug}/spec.md` — this is your contract
2. Read the project's `CLAUDE.md` — these are your constraints
3. Search memory for relevant patterns: `mcp__memory__search_nodes({ query: "patterns" })`

## Anti-Anchoring

Before writing code, use Sequential Thinking to challenge your first implementation instinct:
- What assumptions am I making about the architecture?
- Is there a simpler approach I'm not seeing?
- Am I over-engineering or under-engineering?
- What would break if my assumptions are wrong?

## Build

You have complete freedom in HOW you implement. No prescribed methodology.

Your only hard constraints:
- Follow the spec's acceptance criteria and edge cases
- Follow CLAUDE.md project conventions
- All verifications in `.claude/build/verify.sh` must pass — the Stop hook enforces this

Run `bash .claude/build/verify.sh` frequently — it's your feedback loop, not a final gate.

For `playwright`-type verifications in the spec: use MCP Playwright tools to execute the described flow, then write evidence files to the paths specified. verify.sh checks for their existence.

## Done Condition

When all acceptance criteria are met AND `bash .claude/build/verify.sh` passes:

1. Update `.claude/build/{slug}/spec.md` Status → `CERTIFYING`
2. Return a summary (<500 words) of:
   - What was implemented
   - Key implementation decisions
   - Files changed
   - Test coverage
   - Any concerns for the certifier
