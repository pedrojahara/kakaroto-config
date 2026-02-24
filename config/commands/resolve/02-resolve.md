# Phase 2: Resolve

You are fixing a bug in a clean context. Your sole input is the diagnosis file.

## Start

Read `.claude/resolve-diagnosis.md`. This contains the root cause analysis, reproduction test, and verification method from Phase 1.

Also read the project's `CLAUDE.md` for structure and conventions.

## Your Goal

Fix the root cause and prove it works. You have full autonomy on HOW — use any tools, any approach.

## Completion Criteria (ALL must pass)

You are NOT done until all four checks pass:

1. **Reproduction test → GREEN**: The test from Phase 1 that was RED must now pass
2. **npm test → PASS**: Full test suite passes (`npm test`)
3. **npx tsc --noEmit → PASS**: No TypeScript errors
4. **E2E verification → WORKS**: The actual user-facing flow works, verified using the method documented in the diagnosis (Playwright for UI, curl for API, bash for services/jobs)

Run all four checks explicitly. Do not assume they pass.

## How to Work

- Start from the suggested fix in the diagnosis, but you are NOT bound to it — if you find a better approach, use it
- Make the **minimum change** that fixes the root cause. Do not refactor surrounding code
- After each change, run the checks. Iterate until all four pass
- Use `mcp__sequential-thinking__sequentialthinking` when you need to reason through complex logic
- Use `mcp__context7__query-docs` if you need library documentation
- Search memory (`mcp__memory__search_nodes`) for architectural context if needed

## Step-Back Mechanism

If you've tried the same approach 2-3 times without progress:

1. **STOP coding**
2. Use `mcp__sequential-thinking__sequentialthinking` to:
   - List what you've tried and why it failed
   - Question your assumptions about the root cause
   - Consider if the diagnosis was wrong or incomplete
   - Generate a **completely different** approach
3. Try the new approach

Track what you've tried. Never repeat the same approach.

## When Done

Update `.claude/resolve-diagnosis.md` by appending:

```markdown
## Resolution: VERIFIED

### Fix Applied
<what you changed and why — be specific about files and logic>

### Verification Results
- Reproduction test: PASS
- npm test: PASS
- tsc --noEmit: PASS
- E2E verification: PASS (<method used>)
```

Then commit and push:
- Commit message: `fix: <one-line summary>`
- Include all changed files (source + test)

## If You Cannot Fix It

After **5+ genuinely different attempts** (not variations of the same idea), write a failure report:

Update `.claude/resolve-diagnosis.md` by appending:

```markdown
## Resolution: FAILED

### Attempts
| # | Approach | Result | Why It Failed |
|---|----------|--------|---------------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |

### What to Investigate Next
<your best assessment of what a human should look at>
```

## Constraints

- Do NOT ask the user questions — work autonomously
- Do NOT modify tests from Phase 1 to make them pass (fix the production code instead)
- Do NOT introduce new dependencies unless absolutely necessary
- Keep changes minimal and focused on the bug
