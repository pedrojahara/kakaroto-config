---
name: build-verify
description: "Verification designer for /build. Designs QA-style human-action test scripts."
user-invocable: false
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - mcp__memory__search_nodes
---

# VERIFY — Design QA Test Scripts

Design HOW A HUMAN TESTS the feature.

**Input:** `$ARGUMENTS` = `{slug}`. Spec at `.claude/build/{slug}/spec.md` with Status: UNDERSTOOD.

## Boundaries

- **Authority:** ONLY set Status to `VERIFIED`.
- **Write scope:** `.claude/build/{slug}/spec.md` and `.claude/build/verify.sh`.

---

## Step 1: Read Spec

Read `.claude/build/{slug}/spec.md`. Understand what was approved. If helpful, explore relevant pages/components to understand the UI surface.

## Step 2: Design QA Verification

The verification system has two layers — you design the second one:

- **V1-V3 (automatic):** Unit tests, TypeScript, build. Already handled by verify.sh. Don't design these.
- **V4+ (your job):** What a human QA would test — visual correctness, user flows, states, edge cases. Things that code checks alone can't catch. These are executed by the LLM using Playwright MCP tools.

Design V4+ as human-action scripts. Think: **what would convince a skeptical user that this works?**

```
V4: {Test name}
  - human-steps:
    1. Open [page/URL]
    2. Click [button/element]
    3. Fill [field] with [value]
    4. Verify [expected result visible on screen]
```

Every step must be a concrete, observable action.

### Gate → `AskUserQuestion`

Present each verification as a numbered human-action script. Options: `"Approve verifications"` / `"Needs changes"`.

**Empty response guard:** If the user's response is empty, blank, whitespace-only, or does not clearly match one of the two options, treat it as an accidental submission. Do NOT proceed — re-ask the exact same question immediately. This gate requires an explicit, non-empty selection of "Approve verifications" to pass.

Iterate until approved.

## Step 3: Write Artifacts

After gate passes, produce both outputs:

1. **Spec:** Add `## Verification` section to `.claude/build/{slug}/spec.md` (before `## Source`). Set Status → `VERIFIED`.
2. **verify.sh:** Read `.claude/skills/build-verify/verify-template.md`. Write `.claude/build/verify.sh` following the template — V1-V3 baselines only.

## Handoff

Write `.claude/build/{slug}/next-action.md`:

```
## Context
build-verify complete. Verification scripts V4-VN designed, verify.sh generated (V1-V3 baselines only).

## Action
1. Edit `.claude/build/{slug}/spec.md`: change `Status: VERIFIED` to `Status: BUILDING`
2. Call `Skill("build-implement", args: "{slug}")`
```
