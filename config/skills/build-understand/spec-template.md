# Spec Template

Generate `.workflow/build/{slug}/spec.md` using this template. Replace all `{placeholders}` with actual content from the approved gates.

```markdown
# {Feature Title}

Status: UNDERSTOOD
Complexity: {LITE | FULL}

## What
What this feature does, in plain language, from the user's perspective.

## Acceptance Criteria
- [ ] Observable behavior 1
- [ ] Observable behavior 2

## Edge Cases
- What happens when X?

## Decisions Made
{Decisions surfaced at the gate and resolved by the user}
- **{Decision}:** {Choice} — {rationale}

## Constraints
{DO NOT rules, architectural constraints, anti-patterns}
- DO NOT ...
- MUST ...

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

- `Complexity: LITE` when ALL: single-pattern change, 1-3 files, no new UI flow/data model/endpoint
- `Complexity: FULL` otherwise (default if unsure)
- Status goes to `UNDERSTOOD` — the understanding gate already passed
- Sections above `## Implementation Plan` describe WHAT (executive summary)
- `## Implementation Plan` preserves EVERYTHING from the plan — code, files, architecture, execution order
- `## Decisions Made` captures decisions from the gate (omit if none)
- `## Constraints` captures DO NOT rules from plan + analysis
- `## Verification` section is added later by build-verify, not by this template
- **ZERO INFORMATION LOSS:** Every piece of information from the input MUST appear in the spec
