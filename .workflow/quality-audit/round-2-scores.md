# Round 2 — Rubric Scores

Scale 1–5.

| Eixo | R R1 | R R2 | Δ | S R1 | S R2 | Δ |
|---|---|---|---|---|---|---|
| 1. Precision | 4 | 5 | +1 | 4 | 4 | 0 |
| 2. Recall | 3 | 4 | +1 | 4 | 4 | 0 |
| 3. Severity calibration | 2 | 4 | +2 | N/A | N/A | — |
| 4. Scope discipline | 3 | 5 | +2 | 3 | 5 | +2 |
| 5. Boundary respect | 3 | 5 | +2 | 2 | 4 | +2 |
| 6. Fail-safe | 3 | 5 | +2 | 4 | 5 | +1 |
| 7. Contract integrity | 4 | 5 | +1 | 4 | 5 | +1 |
| 8. AC fidelity | 3 | 5 | +2 | — | — | — |
| 9. Rule-of-3 | — | — | — | 3 | 5 | +2 |
| 10. Cost efficiency | 4 | 4 | 0 | 4 | 4 | 0 |
| **Average** | **3.22** | **4.66** | **+1.44** | **3.43** | **4.50** | **+1.07** |

Recall stops at 4 (not 5) porque:
- R: cenários de TOCTOU/race em shapes incomuns ainda podem escapar; classificação correta depende de leitura atenta do diff. Limite do audit material.
- S: helper duplicado com nomenclatura muito diferente pode escapar ao Grep. Limite teórico.

Cost efficiency 4 (not 5) porque:
- Diff-only + Grep-before-extract pode exigir 1-2 calls extras; tradeoff aceitável vs rigor ganhado.
