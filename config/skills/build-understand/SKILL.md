---
name: build-understand
description: "Requirements designer for /build."
user-invocable: false
model: opus
context: fork
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - mcp__sequential-thinking__sequentialthinking
  - mcp__memory__search_nodes
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - WebSearch
  - WebFetch
---

# ALIGN — Understand Requirements

Understand WHAT to build. A spec is only written after the gate passes.

**Input:** `$ARGUMENTS` = `{slug} {feature description or plan file path}`. Parse slug (first token), rest is context.

## Boundaries

- **Authority:** You may ONLY set Status to `UNDERSTOOD`. Never write VERIFIED, BUILDING, CERTIFYING, or DONE.
- **Scope:** Do NOT read implementation code — no services, types, utilities, handlers.
- **Gate:** The understanding gate below is mandatory. Requires explicit user approval via `AskUserQuestion` before proceeding.

---

## Step 1: UNDERSTAND — What are we building?

### Gather Context

1. Read the input (plan file or description) to understand user intent
2. Read CLAUDE.md for project conventions
3. Search memory: `mcp__memory__search_nodes({ query: "relevant-topic" })`
4. Explore product surface — Glob routes, pages, UI features:
   ```
   Glob("**/pages/**/*.tsx"), Glob("**/app/**/page.tsx"), Glob("**/routes/**")
   ```
5. If needed: use Context7, WebSearch, or WebFetch for external API/library docs

### Challenge Assumptions (Sequential Thinking)

After gathering context, run Sequential Thinking (3 thoughts):
- **Thought 1 (ASSUMPTIONS):** List every assumption embedded in the user's request. What is being taken for granted? What already exists in the codebase that might make this unnecessary or different?
- **Thought 2 (FRAGILITY):** Which assumption, if wrong, would change what we build? Search codebase (Glob/Grep/Read) for evidence that confirms or refutes it.
- **Thought 3 (DECISIONS):** What decisions will the implementer face about WHAT to build that the current information doesn't answer? What behavior is ambiguous? What edge cases need a product decision (not an engineering one)?

**Quick-exit:** If the challenge reveals the feature already exists or the problem is trivially solvable, present the finding at the gate with the "Already solved" option. Do not force a spec.

### Synthesize

Form a clear picture of:
- **What the feature does** from the user's perspective
- **What changes** in the UI/behavior the user will see
- **Edge cases** and error states
- **What is NOT in scope** — explicit exclusions
- **Assumptions validated/refuted** from the challenge step

### Classify Complexity

Before writing the spec, assess:
- Does this follow an existing pattern exactly? (LITE candidate)
- New UI flow, data model, or endpoint? (→ FULL)
- Touches 4+ files or crosses architectural boundaries? (→ FULL)
- Unsure? → FULL (safe default)

Include the classification in your gate presentation: "Complexity: LITE — follows existing pattern" or "Complexity: FULL — new [X]"

### Gate → Decision Surface + Echo-Back

Present understanding via `AskUserQuestion` in this exact structure:

**Section 1 — Open Decisions** (only if Thought 3 found decisions):

> **I need your input on {N} decisions before writing the spec:**
>
> 1. **{Decision}** — {context from codebase}. Options: (a) ... (b) ...
> 2. ...

If Thought 3 found zero decisions, skip Section 1 entirely.

**Section 2 — Echo-Back Walkthrough** (always):

> **Here's the feature as a user story — read as if you're using it:**
>
> "You open [page]. You [action]. The system [response].
> If [edge case], then [behavior]..."
>
> **What will NOT change:** [explicit exclusions]
>
> **Assumptions I challenged:** [what I checked and found]

Complexity classification included as before.

Options: `"Correct"` / `"Needs clarification"` / `"Already solved — cancel build"`

**Empty response guard:** If the user's response is empty, blank, whitespace-only, or does not clearly match one of the options, treat it as an accidental submission. Do NOT proceed — re-ask the exact same question immediately. This gate requires an explicit, non-empty selection to pass.

If "Needs clarification": iterate with follow-up questions until the user confirms.
If "Already solved": return `{slug}: CANCELLED` — do not write spec.

### Refinement (FULL only)

**Skip if Complexity: LITE** — proceed directly to Step 2.

After the gate passes with "Correct", run Sequential Thinking (2 thoughts):
- **Thought 1 (GAPS):** If we build exactly this spec, what could go wrong? What questions did we not ask? What interactions with existing features might break?
- **Thought 2 (RISKS):** Which gaps are spec-level (change what we build) vs implementation-level (change how we build)? Only spec-level gaps matter here.

If spec-level gaps found, present via `AskUserQuestion`:
- The 2-3 most concrete gaps/risks
- For each: what changes in the spec if this matters

Options: `"Spec is complete — no changes"` / `"Adjust scope: [user describes]"`

If "Adjust scope": incorporate changes into synthesis, re-present updated understanding, then proceed.
One round maximum — do not loop indefinitely.

---

## Step 2: WRITE SPEC

Pre-check: gate passed, spec contains no implementation details.

1. Read `.claude/skills/build-understand/spec-template.md`
2. Write spec to `.claude/build/{slug}/spec.md` using the template
3. Populate `## Original Request` with raw $ARGUMENTS text (everything after slug), verbatim
4. Status → `UNDERSTOOD`

## Output

Return ONLY: `{slug}: UNDERSTOOD` or `{slug}: CANCELLED` (if user chose "Already solved").

## Handoff

Before returning, write `.claude/build/{slug}/next-action.md` — a single line:

If **Complexity: FULL**:
```
Skill("build-verify", args: "{slug}")
```

If **Complexity: LITE**:
```
Skill("build-implement", args: "{slug}")
```
