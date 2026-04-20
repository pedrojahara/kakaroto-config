# Round 3 — Simulated Runs (sanity + external re-check)

Prompts unchanged since commit 68f0ccf. No edits in Round 2. Purpose of Round 3:
1. Re-hit external sources per "every 2 rounds" mandate.
2. Confirm no new (impact ≥ médio, conf = alta) opportunities.
3. Achieve 2nd consecutive empty matrix → convergence.

## External re-check (2026-04-20 searches)

New material surveyed:
- **Meta "Just-in-Time Testing" / "Dodgy Diff"** (InfoQ, April 2026): reframes code change as a *semantic signal* and pairs with mutation testing + intent-aware workflow. 4x bug-detection uplift. Our M1 behaviour-change rule maps to the semantic-signal principle; exemplars are present. No new action required.
- **Meta structured-prompting technique** (VentureBeat, April 2026): structured prompting boosts code-review accuracy to 93%. Our current prompts already use structured tables + explicit checklists + severity taxonomy. No new action required.
- **arxiv 2505.16339 Rethinking Code Review with LLMs**: confirms gap between syntax and semantic intent. Mitigation = explicit intent checks. Our AC + behaviour-change rules do this.
- **arxiv 2511.07017 Fine-grained code review benchmarks**: confirms LLMs struggle with *rationale* — but on OUR scope (diff-bound, pattern-matching severity) this is already absorbed.
- **GitHub Issue #46727 (Opus 4.6 hallucinations)**: outdated (4.6). Our prompts are for 4.7 and diff-only scope is already the explicit mitigation.

Conclusion: no new fix qualifies under the (impact ≥ Médio, conf = Alta) rule.

## 30-scenario re-walk (abridged)

Walked all 30 scenarios a second time with the Round-1 prompts fresh. All outcomes match Round 2 exactly (all ✅ or orchestrator-out-of-scope).

No regressions. No new failure modes. No new false positives introduced by Round-1 edits.

## Stability signal

Same prompts, same simulated outcomes, two rounds in a row. Scores identical to Round 2:
- R average: 4.66
- S average: 4.50
