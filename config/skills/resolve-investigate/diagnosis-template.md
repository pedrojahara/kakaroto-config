# Diagnosis Template

Two templates in one file.

- **LITE** is the default (Phase B + Phase C, ~80% of cases).
- **FULL** is used only when Phase D is entered (browser bugs, intermittent, complex, user-requested deep dive).

**Compatibility rule:** LITE is a strict subset of FULL. No field is renamed or moved. Downstream skills (`resolve-verify`, `resolve-fix`, `resolve-certify`) MUST tolerate missing optional sections via "if section exists" checks.

---

## LITE Template (default)

Use in Phase B (Trivial) and Phase C (Standard). Write to `.workflow/resolve/{slug}/diagnosis.md`.

```markdown
# Diagnosis: {One-Line Bug Summary}

Status: INVESTIGATING
Severity: {TRIVIAL | STANDARD | VAGUE}
Fix Type: {code | infra | config | manual}
Outcome: {fixed | diagnosed | instructions | cancelled}
Committed: {yes | no}
Slug: {slug}

## Bug Description

{What the user reported. Expected vs actual behavior.}

## Signals (Phase A)

- Matched patterns: {archetype_ids or "none"}
- Stack trace: {file:line or "absent"}
- Scope: see `.workflow/resolve/{slug}/scope.txt`

## Root Cause

{One paragraph. Reference evidence from the investigation (file:line).}

## Hotspots

| File:Line   | Reason                 |
| ----------- | ---------------------- |
| {path:line} | {why this is relevant} |

## Reproduction Test

- File: {path to test file}
- Status: RED
  (or: "UNTESTABLE — {reason}" with manual reproduction steps)
  (or: "SKIPPED — investigation-only mode, Fix Type != code")

## QA Reproduction Flows

(MANDATORY except when Severity == TRIVIAL — Phase B skips reproduction by design)

R1: {Flow name -- primary reproduction path}

- preconditions: {state needed before starting}
- human-steps:
  1. {action}
  2. {action}
- expected-bug: {what the bug looks like}
- expected-fixed: {what correct behavior looks like}
- checks:
  - console: no-errors
  - text: visible "{key text}"
  - (other assertions as needed)

## Suggested Fix

{2-4 lines. If Fix Type != code, these are instructions to the user instead of code edits.}
```

---

## FULL Template (Phase D only)

Use only when Phase D is entered. Adds rigor-critical sections on top of LITE.

```markdown
# Diagnosis: {One-Line Bug Summary}

Status: INVESTIGATING
Severity: COMPLEX
Fix Type: {code | infra | config | manual}
Outcome: {diagnosed | instructions}
Committed: no
Slug: {slug}

## Bug Description

{What the user reported. Expected vs actual behavior.}

## Signals (Phase A)

- Matched patterns: {archetype_ids or "none"}
- Stack trace: {file:line or "absent"}
- Scope: see `.workflow/resolve/{slug}/scope.txt`
- Why Phase D: {browser_visual | intermittent | strike #3 escalation | phase_d_resume | user requested}

## Production Logs

- Command run: `{exact command}`
- Output:
```

{raw terminal output}

```
(or "N/A — not a production bug" | "NOT AVAILABLE — {reason}")

## Investigation Trail
| Step | Action | Finding |
|------|--------|---------|
| 1    | {grep/read/bash} | {finding} |
| 2    | ...    | ...     |

## Codebase Context
- **Data flow:** {how data moves through the relevant path}
- **Key files:** {file:line references}
- **Patterns:** {relevant architectural patterns observed}

## Hypotheses
| # | Hypothesis | Evidence For | Evidence Against | Verdict |
|---|-----------|-------------|-----------------|---------|
| 1 | {structurally different} | ... | ... | SELECTED / REJECTED |
| 2 | {structurally different} | ... | ... | SELECTED / REJECTED |
| 3 | {structurally different} | ... | ... | SELECTED / REJECTED |

Hypotheses MUST be structurally different (e.g., "missing null check" vs "race condition" vs "wrong API endpoint"). Variations of the same idea do not count.

## Root Cause
{Clear explanation of WHY the bug happens, referencing evidence.}

## Hotspots
| File:Line | Reason |
|-----------|--------|

## Reproduction Test
- File: {path}
- Status: RED
(or "UNTESTABLE — {reason}")

## QA Reproduction Flows

R1: {Flow name}
  - preconditions: ...
  - human-steps: ...
  - expected-bug: ...
  - expected-fixed: ...
  - checks: ...

R2: {Alternative path, if applicable}
  - ...

## Suggested Fix
{Brief description of the fix approach. Do NOT implement unless TRIVIAL.}

## Rejected Approaches
{Approaches considered and why discarded.}

## Concerns
{Low-confidence areas, risks of the suggested fix, things to watch out for.}
{Include "scope truncated at 10 files — refactor too wide" if regression_with_commit hit the cap.}
```

---

## Status Values

- `INVESTIGATING` -- investigation in progress
- `DIAGNOSED` -- root cause identified, ready for user review (verify) or already fixed (trivial)
- `VERIFIED` -- user approved diagnosis + QA flows, ready for fix
- `FIXING` -- resolve-fix is working on it
- `CERTIFYING` -- fix applied + committed, deploy/production QA pending
- `VERIFIED_PROD` -- fix confirmed in production
- `FAILED` -- could not resolve

## Severity Values

- **TRIVIAL** -- Phase B escape hatch applied (single-line fix, stack trace present, tests pass)
- **STANDARD** -- Phase C single-hypothesis resolution (1-3 files, pattern match or freelance)
- **COMPLEX** -- Phase D deep investigation (browser bugs, intermittent, strike #3 escalation, or user-requested)
- **VAGUE** -- terminal state, bug report too vague and user cancelled (or strike-3 abort)

## Fix Type Values

- **code** -- resolve-fix edits source code normally (default)
- **infra** -- Terraform/GCP/Docker/CI action needed. Orchestrator reports instructions, skips resolve-fix.
- **config** -- config file edit outside production source. Orchestrator reports instructions.
- **manual** -- human action required. Orchestrator reports instructions.

## Outcome Values (routing signal for the orchestrator)

- **fixed** -- Phase B applied a one-line code fix, tests passed. Orchestrator commits + exits.
- **diagnosed** -- normal flow, `Fix Type: code`. Orchestrator proceeds to verify → fix → certify.
- **instructions** -- `Fix Type != code`, OR strike-3 abort. Orchestrator reads `## Suggested Fix` and reports to user, no commit.
- **cancelled** -- `Severity: VAGUE`, user cancelled at vague gate. Orchestrator reports, no commit.

## Committed Values

- **no** -- orchestrator has not committed yet (default; applies to all Outcomes at Phase A write time)
- **yes** -- set by orchestrator after `git commit` (not by sub-skills)

## Archetype Format (for `## Resolve Patterns` in project CLAUDE.md)

Archetypes use **structured fields**, not a DSL. Parsed deterministically by `resolve-investigate` Phase A.3.

```markdown
- **{id}**
  - requires-signals: signal1, signal2
  - requires-error: "literal1" | "literal2" (optional)
  - hypotheses:
    - (a) first hypothesis (usually the cheapest to falsify)
    - (b) second hypothesis
    - (c) third hypothesis
```

**Matching rule:** archetype matches if ALL `requires-signals` are true AND (if `requires-error` present) `error_literal` matches at least one of the listed literals (case-insensitive substring). Archetypes evaluated in document order.

## Rules

- Status starts at `INVESTIGATING`, advances to `DIAGNOSED` when investigation is complete
- `Outcome` and `Committed` are orthogonal — `Outcome` describes what the sub-skill achieved; `Committed` is written by the orchestrator
- QA Reproduction Flows are MANDATORY except when `Severity == TRIVIAL` (Phase B skips reproduction by design)
- FULL template requires 3+ structurally different hypotheses; LITE does not require a hypotheses table
- Investigation Trail is FULL-only (Phase D audit trail)
