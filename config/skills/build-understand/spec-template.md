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

Verification-Mode: {both | local-only}
{`both` = runner executes locally in build-implement AND against prod in certify.sh (default).
`local-only` = skip prod run — use only when user opted out of prod auth during the Credentials Gate.}

Pre-condition: {optional — e.g. "authenticated user via e2eLogin()"}

V4: {Test name}
  - steps:
    1. Open {BASE_URL}/[path]
    2. Click [element]
    3. Verify [expected result]
  - checks:
    - console: no-errors
    - text: visible "[key text]"

{URL rule: use `{BASE_URL}` literal — never hardcoded localhost or prod.
Fixture rule: file paths must live under `.workflow/build/{slug}/fixtures/`, never `/Users/...`.}

## Rejected Alternatives
{Only for DELIBERATION FILE inputs — one-line summary of each rejected scenario from the deliberation, so context is preserved without polluting Implementation Plan. Omit section for PLAN FILE or DESCRIPTION inputs.}

## Implementation Plan
{Content depends on input kind:
- **PLAN FILE input:** ENTIRE file content verbatim (Zero Information Loss). Any branch ruled out during Coherence Check is struck through with ~~text~~ and annotated.
- **DELIBERATION FILE input:** ONLY the refined/chosen approach — rejected scenarios go into ## Rejected Alternatives above.
- **DESCRIPTION input:** the $ARGUMENTS description verbatim.
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
- `## Rejected Alternatives` present ONLY for DELIBERATION FILE inputs (summaries of rejected scenarios). Omit otherwise.
- **ZERO INFORMATION LOSS applies to PLAN FILE and DESCRIPTION inputs only.** For DELIBERATION FILE inputs, rejected scenarios are INTENTIONALLY summarized (not reproduced verbatim) in `## Rejected Alternatives` — keeping them in `## Implementation Plan` would pollute execution guidance.
