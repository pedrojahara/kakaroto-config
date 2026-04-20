# Round 1 — Simulated Runs

Simulated against current `~/.claude/agents/code-reviewer.md` and `~/.claude/agents/code-simplifier.md` (state before any Round-1 edits). COMPLEX cenários são simulados nas duas ordens (build-certify: reviewer→simplifier; resolve-certify: simplifier→reviewer). Observações em bullets curtos.

Notation: R = reviewer, S = simplifier. ✅ correct, ❌ failure, ⚠ partial.

## S1 — SQL injection
- R tool calls: Read(src/api/users.ts), Edit (parameterise), Bash(tsc). 3 calls.
- R detects CRÍTICO. Fixes to `db.query('SELECT ... LIKE $1', [\`%${search}%\`])`.
- AGENT_RESULT: STATUS PASS, ISSUES_FOUND 1, ISSUES_FIXED 1, BLOCKING true. ✅
- Observação: clean. Custo adequado.

## S2 — Hardcoded secret
- R: Read, Edit (revert to env), Bash(tsc). 3 calls.
- Detects CRÍTICO, fixes. ✅

## S3 — eval() (COMPLEX, reviewer→simplifier)
- R: Read, Edit (remove body, throw NotImplementedError OR request manual review for mathjs), Bash(tsc).
- Detects CRÍTICO. But reviewer-only cannot pick a replacement library safely — may end up either removing body (breaks feature) or leaving TODO. ⚠ Risk: auto-fix introduces regression. Current prompt: no guidance for "unknown-safe-replacement" → may overfix.
- S (after R): no clarity issues.
- Observação [FIX]: reviewer should REPORT+GATE when removing a caller API without replacement. Prompt lacks this guard.

## S4 — exec() with variable
- R: Read, Edit (execFile + allowlist), Bash(tsc). Fix ~5 lines. ALTO → fix (<10 lines rule).
- ✅ but allowlist construction requires project knowledge; may be partial.

## S5 — Math.random for auth token
- R detects MÉDIO per current severity table. → REPORT only, no fix. ❌ Security-relevant randomness should be CRÍTICO; current prompt miscalibrates.
- AGENT_RESULT: STATUS PASS (no blocking), ISSUES_FOUND 1, ISSUES_FIXED 0. But semantically this should BLOCK.
- Observação [FIX, HIGH impact]: table row "Math.random() p/ segurança: MÉDIO" is wrong when context is AUTH/TOKEN/SESSION/PASSWORD/CSRF. Split by context.

## S6 — console.log PII
- R: detects ALTO. Fix is 1 line (remove `password` from log object). ✅

## S7 — Deserialize unvalidated
- R detects (current prompt places Zod under "Tipagem CRÍTICO"). Fix adds schema + parse (~6 lines).
- ✅ but reviewer may over-design schema without real shape signal. Low risk, acceptable.

## S8 — Auth race condition (COMPLEX, resolve-certify simplifier→reviewer)
- S (first): nothing. ✅
- R (second): detects ALTO TOCTOU. Fix via Redis WATCH/MULTI or SET NX may be 8–15 lines. Under "<10 lines" rule: borderline; reviewer might skip.
- ⚠ High-risk bug underpatched because of size heuristic.
- Observação [FIX, HIGH]: "<10 lines" is a poor proxy; replace with confidence-based rule.

## T1 — `any`
- R: CRÍTICO, fix by restoring types. ✅

## T2 — @ts-ignore
- R: CRÍTICO, fix root cause via type guard. Requires codebase knowledge; tsc revert protects. ✅

## T3 — Missing return type in .d.ts (TRIVIAL, no security trigger)
- Orchestrator skips R/S entirely (TRIVIAL build-certify without security trigger). Issue not caught by AGENTS.
- Observação: ORCHESTRATOR gap, not agent. Record in final-report, not fixable at agent level per audit scope.

## T4 — Zod missing on public endpoint
- R: CRÍTICO (CLAUDE.md Zod mandate). Fix. ✅

## T5 — Unsafe `as` across union
- R: ALTO. Fix with narrowing (~3 lines). ✅

## B1 — Null after optional chain
- R: ALTO. Fix 1 line (`?.toUpperCase() ?? ''`). ✅

## B2 — Missing import
- R: CRÍTICO (tsc fails). Fix adds import. tsc re-pass. ✅

## B3 — Orphan `charge` (bug signal)
- R: ALTO. Fix: return chargeId. ✅
- Trap: simplifier if invoked (COMPLEX) must NOT delete `charge`. With reviewer-first order, reviewer fixes first → simplifier has nothing. ✅

## B4 — Off-by-one in test file
- R: current prompt doesn't call out "test files are contracts too." May treat as a test file to skip. ⚠
- Expected behaviour: fix the test (it's asserting wrong contract). Likely correct since `npm run test` would fail; but reasoning is brittle.
- Observação [FIX, MED]: add "Test files are contracts — apply all rules" to reviewer.

## B5 — Unawaited promise
- R: ALTO. Fix 1 line add `await`. ✅

## C1 — Bad names (COMPLEX, R→S)
- R: CRÍTICO `any` (d: any[]). Fix typing → `events: Event[]`.
- S (after R): renames `fn`→`valuesSince`, `d`→`events` (already done), `tmp`→`recent`, `t`→`sinceTimestamp`. ✅

## C2 — 4-level nesting (COMPLEX, R→S)
- R: nothing.
- S: detects nesting > 2 (CLAUDE.md). Applies early returns + filter/reduce. tsc pass. ✅

## C3 — Triple ternary (COMPLEX resolve-certify, S→R)
- S (first): detects; applies record lookup.
- R (second): no issues. ✅

## C4 — Commented-out code (STANDARD resolve-certify)
- S not invoked (resolve STANDARD = reviewer only). Issue uncaught.
- Observação: ORCHESTRATOR scope, not agent bug.

## C5 — Dead code + unused imports (COMPLEX, R→S)
- R: nothing.
- S: removes unused `DateTime` import + `oldHelper`. tsc pass. ✅

## D1 — Reimplement existing slugify (COMPLEX, R→S)
- R: nothing.
- S: current prompt says "Buscar Duplicações: Grep em utils/, services/, helpers/". S greps, finds existing `utils/string.ts` slugify, replaces.
- ⚠ Risk: S may grep for exact name "slugify" and miss semantic duplicates. Detection depends on S actually running the grep — prompt lists as a step but doesn't enforce order.
- Observação [FIX, MED]: make Grep-before-extract MANDATORY as the first step when new helper/function is observed.

## D2 — 3+ occurrences (COMPLEX, R→S)
- S: extracts `requireBearer` helper. ✅

## D3 — 2x trap (COMPLEX resolve-certify S→R)
- S: rule-of-3 table says "aparece 2x → Manter duplicado". Should skip.
- ⚠ Risk: if "two handlers serve different stakeholders" hint is weak, S might rationalise "close enough" and extract. Current prompt doesn't mention independent-evolution caveat.
- Observação [FIX, MED]: add "even at 3+, if occurrences serve independent stakeholders/domains and are likely to evolve separately, KEEP duplicated."

## A1 — All AC covered (spec-bound)
- R: reads spec, checklist all pass with code+test evidence.
- Output: AC rows present in table.
- ⚠ Current prompt does NOT require evidence-pointer (file:line or test name). Risk of shallow pass.
- Observação [FIX, MED]: each AC pass row MUST include pointer.

## A2 — One AC missing test
- R: detects code but no test for audit log criterion. Marks BLOCKING ALTO referencing criterion.
- AGENT_RESULT STATUS FAIL, BLOCKING true. ✅
- Partial: ambiguity treatment still vague; acceptable for now.

## M1 — Bug hidden in refactor
- R: current "Bugs Óbvios" section lists null/race/import/orphan but NOT "behaviour change in refactor". Risk of miss.
- If R reads both sides of diff and compares semantics, catches it. But prompt doesn't require semantic diff comparison.
- Observação [FIX, HIGH]: add "When diff replaces a function body, compare pre/post semantics; behaviour change not stated in spec → BLOCKING."

## M2 — Ordering trap (resolve-certify S→R)
- S (first): prompt lists "remover código comentado / eliminar dead code". Empty catch could be misread as dead code.
- Risk: S removes empty catch → reviewer no longer sees the swallow, fails to diagnose.
- Observação [FIX, HIGH]: explicit example — "empty catch is error handling, NOT dead code; DO NOT remove."
- If S correctly leaves catch: R then fixes `any` + empty-catch swallow. ✅ path exists but fragile.

---

## Aggregate failure modes detected

A. **Severity miscalibration** on Math.random-for-security (S5). HIGH impact, HIGH conf.
B. **"<10 lines" heuristic** causes ALTO underpatching on medium-sized but obvious fixes (S8). HIGH impact, HIGH conf.
C. **No "unknown-safe-replacement" guard** — reviewer may auto-fix by deleting caller API (S3). MED impact, MED conf (edge case).
D. **Diff-only scope** not enforced as mandatory first step. MED impact, HIGH conf (Opus 4.7 literal interpretation).
E. **Grep-before-extract / Grep-before-new-helper** not enforced in simplifier (D1). MED impact, HIGH conf.
F. **Rule-of-3** lacks independent-evolution caveat + knowledge-vs-char (D3). MED impact, HIGH conf.
G. **Simplifier boundary** on error handling (empty catch) ambiguous vs "dead code" (M2). HIGH impact, HIGH conf.
H. **Behaviour-change-in-refactor** not in reviewer's bug checklist (M1). HIGH impact, HIGH conf.
I. **Test files** not explicitly treated as first-class by reviewer (B4). MED impact, HIGH conf.
J. **AC evidence pointer** not required (A1). MED impact, HIGH conf.
K. **Fail-safe**: ISSUES_FIXED emitted even when tsc/test cannot verify (no guidance for when verification is unavailable, e.g. .d.ts). MED impact, HIGH conf.
L. **Reviewer self-policy** on auto-fixes: no guard against introducing `any`/`@ts-ignore`/try-swallow in fixes themselves. MED-HIGH impact, HIGH conf.
M. **AGENT_RESULT positioning** — no requirement to be final output; Opus 4.7 literal parsing benefits. MED impact, HIGH conf.

Orchestrator-level gaps (out of audit scope, record for final-report): TRIVIAL .d.ts diffs (T3), STANDARD resolve-certify commented-code (C4).
