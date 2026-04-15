# Spec Template

Generate `.workflow/build/{slug}/spec.md` using this template. Replace all `{placeholders}` with actual content.

```markdown
# {Feature Title}

Status: UNDERSTOOD
Complexity: {TRIVIAL | STANDARD | COMPLEX}

## What

What this feature does, in plain language, from the user's perspective.

## Acceptance Criteria

- [ ] Observable behavior 1
- [ ] Observable behavior 2

## Edge Cases

- What happens when X?

## Decisions Made

{Decisions surfaced during alignment and resolved by the user. Omit section if none.}

- **{Decision}:** {Choice} — {rationale}

## Assumptions

{Assumptions the agent made autonomously (for TRIVIAL/STANDARD where no questions were asked). Omit section if none.}

- {Assumption} — {basis from codebase evidence}

## Constraints

{DO NOT rules, architectural constraints, anti-patterns. Omit section if none.}

- DO NOT ...
- MUST ...

## Verification

{Only for COMPLEX tasks with UI components. Contains V4+ QA test scripts.
Omit section entirely for TRIVIAL/STANDARD tasks.}

V4: {Test name}

- steps:
  1. Open [page/URL]
  2. Click [element]
  3. Verify [expected result]
- checks:
  - console: no-errors
  - text: visible "[key text]"

## Implementation Plan

{FULL content from the plan/arguments. Nothing omitted.
If input was a plan file: include ENTIRE file content.
If input was a description: include it verbatim.
Organize into logical subsections preserving the plan's structure.}

## Source

{Path to plan file, if applicable}

## Original Request

{Raw $ARGUMENTS text, verbatim}
```

## Rules

- `Complexity` — classified by build-understand: TRIVIAL, STANDARD, or COMPLEX
- Status goes to `UNDERSTOOD` — the understanding gate already passed
- Sections above `## Implementation Plan` describe WHAT (executive summary)
- `## Implementation Plan` preserves EVERYTHING from the plan — code, files, architecture, execution order
- `## Decisions Made` captures decisions from alignment (omit if none were asked)
- `## Assumptions` captures autonomous decisions for tasks where no questions were asked (omit if none)
- `## Constraints` captures DO NOT rules from plan + analysis (omit if none)
- `## Verification` contains V4+ QA test scripts for COMPLEX+UI tasks ONLY (omit for TRIVIAL/STANDARD)
- **ZERO INFORMATION LOSS:** Every piece of information from the input MUST appear in the spec
