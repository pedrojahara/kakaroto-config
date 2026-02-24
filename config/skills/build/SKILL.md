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
| No spec OR Status: DRAFTING | `Skill("build-understand", args: "{slug} {$ARGUMENTS}")` |
| Status: SPEC_APPROVED | Execute Verification Gate below |
| Status: BUILDING | `Skill("build-implement", args: "{slug}")` |
| Status: CERTIFYING | Execute Phase 3 below |
| Status: DONE | Inform user, offer `/ship` |

After any Skill returns or Gate completes:
1. Re-read `.claude/build/{slug}/spec.md` Status field
2. Route according to the Phase Routing table above

Never assume the next phase — always check Status.

---

## Verification Gate

This gate runs inline when Status is `SPEC_APPROVED`. Do NOT skip this gate.

1. Read the spec at `.claude/build/{slug}/spec.md`
2. Extract the `## Verification` section
3. Present each verification to the user via `AskUserQuestion`:
   - List each verification (V1–Vn) with its type and what it checks
   - For feature-specific verifications (V4+), explain WHY this verification proves the feature works
   - Ask: "These verifications will prove the feature is complete. The build agent cannot finish until ALL pass. Add, remove, or change any?"
   - Options: "Approve verifications", "Change verifications"
4. If changes requested: update the spec's Verification section and re-present step 3
5. After approval: update spec `Status: SPEC_APPROVED` → `Status: BUILDING`
6. Generate `.claude/build/verify.sh` following the template and rules in `.claude/skills/build/verify-template.md`
7. Re-read Status and route according to the Phase Routing table (will match BUILDING → build-implement)

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
