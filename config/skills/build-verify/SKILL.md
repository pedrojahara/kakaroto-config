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
  - mcp__sequential-thinking__sequentialthinking
  - mcp__memory__search_nodes
---

# VERIFY — Design Verification Scripts

Design HOW A HUMAN TESTS the feature. A spec is only updated after the gate passes.

**Input:** `$ARGUMENTS` = `{slug}`. The spec already exists at `.claude/build/{slug}/spec.md` with Status: UNDERSTOOD.

## Boundaries

- **Authority:** You may ONLY set Status to `VERIFIED`. Never write UNDERSTOOD, BUILDING, CERTIFYING, or DONE.
- **Read scope:** MAY read UI-surface files (pages, components, routes) to understand what's testable. NOT services, handlers, types, or utilities.
- **Write scope:** Edits `.claude/build/{slug}/spec.md` (## Verification + Status)
  and writes `.claude/build/verify.sh` using verify-template.md.
- **Gate:** The verification gate below is mandatory. Requires explicit user approval via `AskUserQuestion` before writing.

---

## Step 1: EXPLORE UI SURFACE

1. Read `.claude/build/{slug}/spec.md` — understand what was approved (Status must be UNDERSTOOD)
2. Explore product surface to understand what's testable:
   ```
   Glob("**/pages/**/*.tsx"), Glob("**/app/**/page.tsx"), Glob("**/components/**/*.tsx")
   ```
3. Search memory for relevant verification patterns: `mcp__memory__search_nodes({ query: "verification" })`

## Step 2: DESIGN VERIFICATION

Design test scripts as a QA person would follow them. Each verification = numbered human actions.

**Format (must match verify-template.md contract exactly):**

```
V4: {Test name}
  - human-steps:
    1. Open [page/URL]
    2. Click [button/element]
    3. Fill [field] with [value]
    4. Verify [expected result visible on screen]
  - evidence: .claude/build/evidence/v4-{name}.md
```

Rules:
- Every step must be a concrete, observable action — no "verify the backend saved correctly"
- Think: **what would convince a skeptical user that this works?**
- Numbering starts at V4 (V1-V3 are baseline checks in verify.sh)
- Evidence path format: `.claude/build/evidence/v{N}-{kebab-name}.md`

### Gate -> `AskUserQuestion`

Present each verification as a numbered human-action script. Concrete enough that someone unfamiliar with the project could follow it.

Options: `"Approve verifications"` / `"Needs changes"`

If "Needs changes": iterate until user approves.

---

## Step 3: WRITE VERIFICATION TO SPEC

Pre-check: gate passed, verifications are concrete human-action scripts.

1. Edit `.claude/build/{slug}/spec.md`:
   - Add `## Verification` section before `## Source`
   - Set Status -> `VERIFIED`

## Step 4: GENERATE verify.sh

1. Read `.claude/skills/build-verify/verify-template.md`
2. Write `.claude/build/verify.sh`:
   - Baselines V1-V3 are fixed (always present, never removed)
   - For each V in the `## Verification` section of the spec:
     `check_evidence "V{N}: {name}" "{evidence path from spec}"`
3. Making it executable is not necessary — build-implementer invokes via `bash .claude/build/verify.sh`

## Output

Return summary (<300 words): verification scripts designed, verify.sh generated, spec location. After the summary, **immediately yield control** — do NOT stop or wait for user input. The orchestrator will re-read Status and route to the next phase.
