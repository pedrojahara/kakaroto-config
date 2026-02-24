---
model: opus
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Task
  - WebFetch
  - WebSearch
  - mcp__sequential-thinking__sequentialthinking
  - mcp__memory__search_nodes
  - mcp__memory__open_nodes
  - mcp__memory__create_entities
  - mcp__memory__add_observations
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - mcp__playwright__browser_navigate
  - mcp__playwright__browser_snapshot
  - mcp__playwright__browser_click
  - mcp__playwright__browser_fill_form
  - mcp__playwright__browser_type
  - mcp__playwright__browser_wait_for
  - mcp__playwright__browser_console_messages
  - mcp__playwright__browser_network_requests
  - mcp__playwright__browser_evaluate
  - mcp__playwright__browser_close
  - mcp__playwright__browser_take_screenshot
  - mcp__playwright__browser_tabs
  - mcp__playwright__browser_press_key
  - mcp__playwright__browser_resize
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
hooks:
  Stop:
    - hooks:
        - type: agent
          prompt: |
            Check if .claude/resolve-diagnosis.md exists.
            If it does NOT exist: respond {"ok": true}
            If it exists, read it. Then:
            If it contains "Trivial Fix Applied: YES": respond {"ok": true}
            If it contains "Resolution: VERIFIED": respond {"ok": true}
            Otherwise run: npm test -- --reporter=dot 2>&1 | tail -20
            And run: npx tsc --noEmit 2>&1 | tail -10
            If BOTH pass: respond {"ok": true}
            If either fails: respond {"ok": false, "reason": "Bug not resolved yet. Tests or TypeScript still failing. Continue fixing."}
          timeout: 120
---
# Resolve: $ARGUMENTS

## Phase 1 — Understand

Launch a **clean-context subagent** to investigate.

```
Task(general-purpose, model: opus):
  Read the file ~/.claude/commands/resolve/01-understand.md and follow its instructions exactly.
  The bug to investigate: $ARGUMENTS
```

After the subagent returns, read `.claude/resolve-diagnosis.md`.

**If "Trivial Fix Applied: YES"** in the diagnosis:
1. Run `npm test` and `npx tsc --noEmit` to confirm everything passes
2. If passing → commit with message `fix: <one-line summary from diagnosis>` and push
3. Clean up: delete `.claude/resolve-diagnosis.md`
4. Report to user and STOP

## Phase 2 — Resolve

If the bug was NOT trivially fixed, launch a second **clean-context subagent**.

```
Task(general-purpose, model: opus):
  Read the file ~/.claude/commands/resolve/02-resolve.md and follow its instructions exactly.
```

After the subagent returns, read `.claude/resolve-diagnosis.md`.

**If "Resolution: VERIFIED"** in the diagnosis:
1. Clean up: delete `.claude/resolve-diagnosis.md`
2. Report to user: summarize what was wrong, what was fixed, and how it was verified

**If resolution failed:**
1. Clean up: delete `.claude/resolve-diagnosis.md`
2. Report the failure analysis to the user with what was tried and what to investigate next

## Rules

1. ZERO paradas ate o final (Stop hook garante)
2. ZERO perguntas ao user (exceto se $ARGUMENTS e vago demais para comecar)
3. Fix minimo — so o necessario para resolver
4. Subagentes SEMPRE com `model: "opus"`
