# Round 1 — Applied Fixes

12 fixes from round-1-matrix.md (impact ≥ Médio, confiança = Alta) applied to `~/.claude/agents/code-reviewer.md` and `~/.claude/agents/code-simplifier.md`.

## Preserved (contract)

- Frontmatter: `name`, `description`, `tools`, `model: opus` — unchanged.
- AGENT_RESULT fields (STATUS, ISSUES_FOUND, ISSUES_FIXED, BLOCKING) — unchanged.
- BLOCKING vs NON-BLOCKING semantics — unchanged (reviewer BLOCKING=true, simplifier BLOCKING=false).

## Reviewer diff summary

| # | Change |
|---|---|
| 1 | Severity table: Math.random split by context (auth/token → CRÍTICO; non-security → BAIXO). |
| 2 | "<10 linhas" heuristic replaced by confidence rubric: fix ALTO only when (a) root cause clear in diff, (b) single mechanical correction, (c) verifiable by tsc+tests. |
| 3 | Step 1 mandatory: `git diff --name-only` → diff-only scope; no Edit outside. |
| 4 | New "Behaviour-change em refactor" row in Bugs Óbvios — BLOCKING when body replacement alters observable behaviour not stated in spec/AC. |
| 5 | Test files explicitly first-class contracts (new section §4). |
| 6 | AC section requires evidence pointer (file:line OR test-name) per item. New AC-AMBIGUOUS row type when criterion is vague. |
| 7 | Fail-safe rule: ISSUES_FIXED only when tsc/tests verified. |
| 8 | AGENT_RESULT must be last output. |
| 9 | Self-policy: reviewer's OWN fixes cannot introduce `any`/`@ts-ignore`/empty catch/PII log/Math.random security. |

## Simplifier diff summary

| # | Change |
|---|---|
| 1 | Step 1 mandatory: `git diff --name-only` → diff-only scope. |
| 2 | Grep-before-extract mandatory whenever diff introduces helper/function. |
| 3 | Rule-of-3 expanded: 3+ occurrences BUT independent-domain stakeholders → keep duplicated; same-syntax-different-concept → keep duplicated. |
| 4 | Explicit NÃO-TOCAR list: try/catch (even empty), throw, directive comments (@ts-/eslint-/TODO), empty-body as no-op, code touched by reviewer in this run. |
| 5 | Fail-safe rule: ISSUES_FIXED only when tsc/tests verified. |
| 6 | AGENT_RESULT must be last output. |

## Notes on compatibility with build-certify / resolve-certify

- AGENT_RESULT schema is byte-stable. Both orchestrators parse STATUS/ISSUES_FOUND/ISSUES_FIXED/BLOCKING and this parse is untouched.
- New AC row types (AC-PASS / AC-FAIL / AC-AMBIGUOUS) appear in the human-readable table only. Orchestrators today rely on STATUS + BLOCKING for gate decisions; AMBIGUOUS does NOT by itself set STATUS=FAIL (only missing AC evidence does). No consumer change required.
- Fail-safe "ISSUES_FIXED only if verified" strengthens the Iron Law in both certifies — re-verify-after-quality-agents already exists, so this is consistent with expected-behaviour downstream.

## Sanity re-simulation (5 random scenarios)

- **S5 (Math.random auth)**: now CRÍTICO → fixed via crypto.randomBytes. STATUS PASS, ISSUES_FIXED=1. ✅ (previously ❌).
- **S8 (race condition)**: ALTO, new rubric → REPORT (fix not mechanically unique). STATUS FAIL, ISSUES_FOUND=1, ISSUES_FIXED=0. Orchestrator will gate/fix. ✅ (previously ⚠ underpatched).
- **C2 (nesting)**: simplifier applies early-return + filter/reduce. Diff-only scope honoured. ✅
- **D3 (2x trap)**: rule-of-3 table explicitly says 1–2x → keep. Simplifier skips with output row "NÃO foi extraído / Rule of 3 não atingida". ✅
- **M1 (behaviour change)**: reviewer detects `* i.qty` semantic change in reduce replacement. BLOCKING. ✅ (previously ❌).

All five move from ❌/⚠ to ✅. Ready to commit.
