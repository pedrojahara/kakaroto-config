---
name: build
description: "Agentic feature development. Understands deeply, builds freely, certifies quality."
disable-model-invocation: true
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - Skill
  - AskUserQuestion
  - mcp__memory__search_nodes
  - mcp__memory__create_entities
  - mcp__memory__add_observations
  - mcp__sequential-thinking__sequentialthinking
---

# /build — Agentic Feature Development

Three phases, each with isolated context. A spec file is the single boundary object.

## Phase Routing

1. Generate slug: first keyword from `$ARGUMENTS` + date (e.g., `auth-2026-02-24`)
2. Check `.claude/build/{slug}/spec.md`
3. Route based on spec Status field:

| Condition | Action |
|-----------|--------|
| No spec exists | `Skill("build-understand", args: "{slug} {$ARGUMENTS}")` |
| Status: BUILDING | `Skill("build-implement", args: "{slug}")` |
| Status: CERTIFYING | Execute Phase 3 below |
| Status: DONE | Inform user, offer `/ship` |

After Phase 1 returns → immediately invoke Phase 2.
After Phase 2 returns → immediately execute Phase 3.

---

## Phase 3: CERTIFY

This phase runs inline (no context fork — it needs to see the full state).

### 3.1 Confirmation Bias Check

Read the spec's edge cases and acceptance criteria. Then read the test files.
Ask yourself via Sequential Thinking:
- Are there happy-path-only tests missing negative cases?
- Which spec edge cases have NO corresponding test?
- Are error paths actually tested or just try/catch wrappers?

If gaps found: write the missing tests. Run them.

### 3.1.1 Verification Review

Read the spec's `## Verification` section. For each entry, assess:

- **command / server-command**: These ran automatically via verify.sh in Phase 2. Confirm they still pass by running `bash .claude/build/verify.sh`.
- **playwright**: Read the evidence file. Assess whether the verification was substantive:
  - Did the agent actually test the described flow (not just create a placeholder file)?
  - Were interactive elements exercised (forms filled, buttons clicked, navigation verified)?
  - Were errors or issues documented?

If any playwright evidence is superficial or missing real verification: re-run it yourself using Playwright tools, then overwrite the evidence file with real results.

### 3.2 Quality Agents (Sequential)

```
Task(code-simplifier) → wait for result → Task(code-reviewer) → wait for result
```

Parse `---AGENT_RESULT---` from each. If code-reviewer returns `STATUS: FAIL`:
- Fix the blocking issues
- Re-run `npm test -- --run` and `npx tsc --noEmit`
- If still failing, re-invoke code-reviewer once more

### 3.3 Final Gate

All three must pass:
```bash
npm test -- --run
npx tsc --noEmit
npm run build
```

If any fails: fix and retry (max 3 attempts). Do NOT skip.

### 3.4 Wrap Up

1. Commit all changes with a descriptive message (conventional commits style)
2. If meaningful architectural decisions or patterns were established, invoke `Task(memory-sync)`
3. Update spec Status → `DONE`
4. Present summary to user:
   - What was built (from spec)
   - Files changed (`git diff --stat` against the branch base)
   - Test coverage (which edge cases are tested)
   - Any open concerns
5. Offer next action: `/ship` for deploy, or manual review
