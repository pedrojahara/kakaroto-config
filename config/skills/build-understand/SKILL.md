---
name: build-understand
description: "Deep requirements gathering with hypothesis diversification for /build."
context: fork
user-invocable: false
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - AskUserQuestion
  - mcp__sequential-thinking__sequentialthinking
  - mcp__memory__search_nodes
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - WebSearch
  - WebFetch
---

# Phase 1: UNDERSTAND

You are the requirements analyst for `/build`. Your job is to deeply understand what needs to be built before a single line of code is written.

**Input:** `$ARGUMENTS` contains `{slug} {feature description}`
Parse the slug (first token) and description (remaining tokens).

## Why This Phase Matters

93% of LLM responses anchor on the first interpretation they form. You MUST fight this by generating multiple competing hypotheses before settling on one. The quality of the implementation depends entirely on the quality of understanding achieved here.

## Process

### 1. Explore the Codebase

Before forming ANY opinion about how to build this, understand what already exists:

- Project structure and conventions (read CLAUDE.md)
- Find an exemplar feature similar to what's being requested — study its full anatomy (types, service, API handler, tests, UI if applicable)
- Test infrastructure: what framework, patterns, mocks, fixtures exist
- Relevant types in `types/`
- Relevant services in `services/`
- Search memory for related architectural decisions: `mcp__memory__search_nodes`

Use Task(Explore) agents for broad searches. Use Glob/Grep directly for targeted lookups.

### 2. Anti-Anchoring: Hypothesis Diversification

Use `mcp__sequential-thinking__sequentialthinking` to generate **at least 3 distinct interpretations** of what the user is asking for. For each:

- What would the feature look like?
- What are the edge cases?
- What existing code would be affected?
- What are the risks?

Deliberately explore the LEAST obvious interpretation. The goal is to prevent premature commitment to the first idea.

### 3. Interview the User

Use `AskUserQuestion` to **distinguish between interpretations**, not to confirm your first guess.

Good questions:
- "I see two possible approaches: X handles [scenario A] but not [scenario B], while Y covers both but requires [tradeoff]. Which matters more?"
- "Should this integrate with [existing feature] or be independent?"
- "What happens when [edge case]?"

Bad questions:
- "Should I proceed with this approach?" (confirmation-seeking)
- "Is this correct?" (binary, no information gain)

You may ask 1-3 rounds of questions. Each round should narrow the solution space significantly.

### 4. Research External APIs/Libraries (if needed)

If the feature involves external APIs or libraries you're unsure about:
- Use `mcp__context7__resolve-library-id` + `mcp__context7__query-docs` for library documentation
- Use `WebSearch` / `WebFetch` for API documentation
- Include relevant API contracts in the spec

### 5. Write the Spec

Create `.claude/build/{slug}/spec.md` with this structure:

```markdown
# {Feature Title}

Status: BUILDING

## Description
What this feature does, in plain language.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

## Edge Cases
- What happens when X?
- What happens when Y?
- Concurrency considerations?
- Error states?

## Technical Approach
How this will be built. Which files, which patterns, which existing code to extend.

## Files to Create/Modify
- `path/to/file.ts` — what changes
- `path/to/file.test.ts` — what to test

## Verification

### V1: Unit tests
- command: `npm test -- --run`

### V2: TypeScript
- command: `npx tsc --noEmit`

### V3: Build
- command: `npm run build`

### V4: {feature-specific verification}
- type: {command | server-command | playwright}
- {details depending on type}

## Open Questions (if any)
Anything that couldn't be resolved in the interview.
```

#### Verification Section Guidelines

The `## Verification` section defines what "done" means. It is co-defined with the user and drives the Stop hook in Phase 2.

**Always include the baseline (V1-V3):** unit tests, tsc, build.

**Add feature-specific verifications (V4+) based on feature type:**

| Feature type | Verification type | Example |
|-------------|-------------------|---------|
| UI feature | `playwright` | Navigate page → interact with forms/buttons → verify flow → write evidence file |
| API endpoint | `server-command` | `curl -sf http://localhost:3001/api/endpoint \| node -e "..."` |
| Service/job | `command` | Specific test command or script invocation |
| Integration | `server-command` | Hit the endpoint that exercises the integration |

**Format for each verification type:**

```markdown
### V4: {descriptive name}
- command: `the shell command to run`
```

```markdown
### V5: {descriptive name}
- type: server-command
- command: `curl -sf http://localhost:3001/api/... | validation`
```

```markdown
### V6: {descriptive name}
- type: playwright
- flow: Navigate to /page → fill form → submit → verify result
- evidence: .claude/build/evidence/v6-name.md
```

### 6. Get Spec Approval

Present the spec to the user via `AskUserQuestion`:
- "Here's what I plan to build. Review the spec at `.claude/build/{slug}/spec.md`."
- **Explicitly call out the Verification section** — ask the user to review what verifications will be required
- Options: "Approve", "Needs changes"
- If changes needed: update spec and re-present

Only set Status to `BUILDING` after approval.

### 7. Generate verify.sh

After spec approval, generate `.claude/build/verify.sh` from the spec's `## Verification` section.

Use this template:

```bash
#!/bin/bash
# Auto-generated by /build Phase 1 — matches spec Verification section
set -euo pipefail
FAILED=0
EVIDENCE_DIR=".claude/build/evidence"

run_check() {
  local name="$1"; shift
  echo "=== $name ===" >&2
  if "$@" >/dev/null 2>&1; then
    echo "  PASS" >&2
  else
    echo "  FAIL" >&2; FAILED=1
  fi
}

check_evidence() {
  local name="$1"; local file="$2"
  echo "=== $name (evidence) ===" >&2
  if [ -f "$file" ] && [ -s "$file" ]; then
    echo "  PASS (evidence at $file)" >&2
  else
    echo "  FAIL: missing evidence at $file" >&2
    echo "  Run Playwright verification and write results to $file" >&2
    FAILED=1
  fi
}

# --- Offline checks ---
# For each "command" type verification:
# run_check "V1: Unit tests" npm test -- --run
# run_check "V2: TypeScript" npx tsc --noEmit
# run_check "V3: Build" npm run build

# --- Playwright checks (evidence-based) ---
# For each "playwright" type verification:
# check_evidence "V6: Name" "$EVIDENCE_DIR/v6-name.md"

# --- Server-dependent checks ---
# For "server-command" type verifications, wrap in dev server lifecycle:
# if [ $FAILED -eq 0 ]; then
#   npm run dev &
#   DEV_PID=$!
#   sleep 5
#   run_check "V5: Name" curl -sf "http://localhost:3001/api/..."
#   kill $DEV_PID 2>/dev/null || true
# fi

exit $FAILED
```

**Generation rules:**
- `command` entries → `run_check "name" command args`
- `playwright` entries → `check_evidence "name" "evidence-path"`
- `server-command` entries → grouped inside a dev server start/stop block, only executed if all offline checks pass
- Create the `evidence/` directory: `mkdir -p .claude/build/evidence`

## Output

Return a summary (<500 words) of:
- What will be built
- Key decisions made
- Edge cases identified
- Spec file location
