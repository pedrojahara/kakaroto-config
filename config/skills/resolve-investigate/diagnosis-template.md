# Diagnosis Template

Generate `.workflow/resolve/{slug}/diagnosis.md` using this template. Replace all `{placeholders}` with actual content from the investigation.

```markdown
# Diagnosis: {One-Line Bug Summary}

Status: INVESTIGATING
Severity: {TRIVIAL | STANDARD | COMPLEX}
Slug: {slug}

## Bug Description
{What the user reported. Expected vs actual behavior.}

## Production Logs
- Command run: `{exact command executed}`
- Output:
```
{raw terminal output pasted here}
```
Or: "N/A -- not a production bug" | "NOT AVAILABLE -- {reason}"

## Investigation Trail
| Step | What I Searched/Ran | What I Found |
|------|-------------------|--------------|
| 1 | {grep/read/bash} | {finding} |
| 2 | ... | ... |

## Codebase Context
- **Data flow:** {how data moves through the relevant path}
- **Key files:** {file:line references}
- **Patterns:** {relevant architectural patterns observed}

## Hypotheses
| # | Hypothesis | Evidence For | Evidence Against | Verdict |
|---|-----------|-------------|-----------------|---------|
| 1 | {structurally different hypothesis} | ... | ... | SELECTED / REJECTED |
| 2 | {structurally different hypothesis} | ... | ... | SELECTED / REJECTED |
| 3 | {structurally different hypothesis} | ... | ... | SELECTED / REJECTED |

Hypotheses MUST be structurally different (e.g., "missing null check" vs "race condition" vs "wrong API endpoint"). Variations of the same idea do not count.

## Root Cause
{Clear explanation of WHY the bug happens, referencing evidence from hypotheses table.}

## Hotspots
| File:Function | Reason |
|--------------|--------|
| {path:function} | {why this is relevant} |

## Reproduction Test
- File: {path to test file}
- Test name: {test name}
- Current status: RED (fails as expected)
- Or: "UNTESTABLE -- {reason}" with manual reproduction steps

## QA Reproduction Flows

Human-action scripts that reproduce the bug in a browser. Used by resolve-fix to verify the fix works.

R1: {Flow name -- primary reproduction path}
  - preconditions: {state needed before starting}
  - human-steps:
    1. Open {page/URL}
    2. {action}
    3. {action}
  - expected-bug: {what the bug looks like on screen}
  - expected-fixed: {what correct behavior looks like}

R2: {Flow name -- alternative reproduction or edge case}
  - preconditions: ...
  - human-steps: ...
  - expected-bug: ...
  - expected-fixed: ...

Each flow must have concrete, observable steps. Include at least 1 flow, more if the bug manifests in multiple paths.

## Suggested Fix
{Brief description of the fix approach -- do NOT implement it unless TRIVIAL.}

## Rejected Approaches
{Approaches considered and why they were discarded.}

## Concerns
{Low-confidence areas, risks of the suggested fix, things to watch out for.}
```

## Status Values

- `INVESTIGATING` -- investigation in progress
- `DIAGNOSED` -- root cause identified, ready for user review
- `VERIFIED` -- user approved diagnosis + QA flows, ready for fix
- `FIXING` -- resolve-fix is working on it
- `CERTIFYING` -- fix applied + committed, deploy/production QA pending
- `VERIFIED_PROD` -- fix confirmed in production
- `FAILED` -- could not resolve

## Severity Classification

- **TRIVIAL:** >95% confidence, single obvious cause (typo, wrong variable, missing import, off-by-one). Fix + verify in Phase 1.
- **STANDARD:** Clear root cause but non-trivial fix. 1-3 files affected. Normal resolve pipeline.
- **COMPLEX:** Multiple interacting causes, race conditions, architectural issues, 4+ files. Full pipeline with quality agents.

## Rules

- Status starts at `INVESTIGATING`, advances to `DIAGNOSED` when investigation is complete
- Severity determines pipeline behavior (TRIVIAL = escape hatch, STANDARD/COMPLEX = full pipeline)
- QA Reproduction Flows are MANDATORY -- they are the verification contract for resolve-fix
- Hypotheses table requires 3+ structurally different entries (2 minimum if bug is very narrow)
- Investigation Trail provides audit trail for debugging the debugging
