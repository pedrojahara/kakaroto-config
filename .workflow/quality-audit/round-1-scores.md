# Round 1 — Rubric Scores

Scale 1–5. Separate scores for reviewer (R) and simplifier (S). Computed from the 30-scenario simulation in `round-1-runs.md`.

| Eixo | R | S | Racional |
|---|---|---|---|
| 1. Precision | 4 | 4 | R/S rarely hallucinate issues; tsc gate protects. |
| 2. Recall | 3 | 4 | R misses: M1 behaviour-change, S5 sec-random misclassed (lost issue because MÉDIO triggered no fix), S8 underpatched due to size rule. S recall solid. |
| 3. Severity calibration | 2 | N/A | Math.random=MÉDIO is wrong in auth context; "<10 linhas" heuristic skews ALTO fix decisions. |
| 4. Scope discipline | 3 | 3 | Both list "git diff --stat" but don't mandate diff-only operation as first step; risk of wandering on COMPLEX diffs. |
| 5. Boundary respect | 3 | 2 | R rarely strays. S risks touching empty catch / error handling (M2). "Dead code" wording conflicts with "error handling keep as-is". |
| 6. Fail-safe | 3 | 4 | S has explicit auto-revert. R has revert on tsc fail but doesn't address "verification unavailable" case. |
| 7. Contract integrity | 4 | 4 | AGENT_RESULT block format correct; position not enforced. |
| 8. AC fidelity (R only) | 3 | – | Checklist works; evidence pointer not required → shallow passes possible. Ambiguity output format vague. |
| 9. Rule-of-3 (S only) | – | 3 | Table says 2x=keep, 3x=extract. Missing: independent-evolution + knowledge-vs-char caveats. |
| 10. Cost efficiency | 4 | 4 | Typical diff uses 3–6 tool calls; no runaway observed. |
| **Average** | **3.22** | **3.43** | — |

## Per-scenario summary

| Cenário | Categoria | R result | S result | Obs |
|---|---|---|---|---|
| S1 | sec | ✅ | n/a | |
| S2 | sec | ✅ | n/a | |
| S3 | sec | ⚠ | n/a | unknown-safe-replacement edge |
| S4 | sec | ✅ | n/a | |
| S5 | sec | ❌ | n/a | severity miscalibration |
| S6 | sec | ✅ | n/a | |
| S7 | sec | ✅ | n/a | |
| S8 | sec | ⚠ | ✅ | size heuristic underpatches |
| T1 | type | ✅ | n/a | |
| T2 | type | ✅ | n/a | |
| T3 | type | – | – | orchestrator skip (TRIVIAL) |
| T4 | type | ✅ | n/a | |
| T5 | type | ✅ | n/a | |
| B1 | bug | ✅ | n/a | |
| B2 | bug | ✅ | n/a | |
| B3 | bug | ✅ | n/a | |
| B4 | bug | ⚠ | n/a | test-file framing missing |
| B5 | bug | ✅ | n/a | |
| C1 | clar | ✅ | ✅ | |
| C2 | clar | n/a | ✅ | |
| C3 | clar | n/a | ✅ | |
| C4 | clar | n/a | – | orchestrator skip (STANDARD resolve) |
| C5 | clar | n/a | ✅ | |
| D1 | DRY | n/a | ⚠ | grep-before-extract not enforced |
| D2 | DRY | n/a | ✅ | |
| D3 | DRY | n/a | ⚠ | independent-evolution caveat missing |
| A1 | AC | ⚠ | n/a | evidence pointer missing |
| A2 | AC | ✅ | n/a | |
| M1 | mixed | ❌ | n/a | behaviour-change-in-refactor miss |
| M2 | mixed | ✅ | ⚠ | empty-catch-vs-dead-code ambiguity |
