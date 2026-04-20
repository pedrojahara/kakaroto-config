# Quality Audit — Final Report

**Target:** `~/.claude/agents/code-reviewer.md` (BLOCKING) and `~/.claude/agents/code-simplifier.md` (NON-BLOCKING), tracked source at `config/agents/`.
**Rounds:** 3 (1 edit round + 2 empty consecutive → converged).
**Commits:** `68f0ccf` (R1), `da91c76` (R2), `3c4ed4d` (R3).
**Scenarios:** 30 simulated diffs across security (8) / typing (5) / bugs (5) / clarity (5) / DRY (3) / AC (2) / mixed traps (2); 3 special files (`.d.ts`, types-only, test-only).

---

## 1. Score evolution (by axis, per agent)

Scale 1–5. Each column is one round.

### code-reviewer (BLOCKING)

| Eixo | R1 | R2 | R3 |
|---|---|---|---|
| 1. Precision | 4 | 5 | 5 |
| 2. Recall | 3 | 4 | 4 |
| 3. Severity calibration | 2 | 4 | 4 |
| 4. Scope discipline | 3 | 5 | 5 |
| 5. Boundary respect | 3 | 5 | 5 |
| 6. Fail-safe | 3 | 5 | 5 |
| 7. Contract integrity | 4 | 5 | 5 |
| 8. AC fidelity | 3 | 5 | 5 |
| 10. Cost efficiency | 4 | 4 | 4 |
| **Média** | **3.22** | **4.66** | **4.66** |

### code-simplifier (NON-BLOCKING)

| Eixo | R1 | R2 | R3 |
|---|---|---|---|
| 1. Precision | 4 | 4 | 4 |
| 2. Recall | 4 | 4 | 4 |
| 4. Scope discipline | 3 | 5 | 5 |
| 5. Boundary respect | 2 | 4 | 4 |
| 6. Fail-safe | 4 | 5 | 5 |
| 7. Contract integrity | 4 | 5 | 5 |
| 9. Rule-of-3 | 3 | 5 | 5 |
| 10. Cost efficiency | 4 | 4 | 4 |
| **Média** | **3.43** | **4.50** | **4.50** |

## 2. Aggregate diff — what changed

334 linhas de mudança nos dois arquivos (diff em `git show 68f0ccf -- config/agents/`). Sumário editorial:

### code-reviewer
- **Severity table (§1 Segurança) expandida** — `Math.random()` context-split (auth/token/session → CRÍTICO; outros → BAIXO), SQL-via-template explícito, Zod ausente explícito, TOCTOU/race row.
- **Substituído "<10 linhas" por rubrica de confiança** — fix ALTO somente quando causa-raiz clara + correção mecanicamente única + verificável por tsc+tests.
- **Adicionado §3 Bugs "Behaviour-change em refactor"** — BLOCKING quando corpo substituído altera comportamento observável não coberto em spec.
- **Adicionado §4 "Arquivos de Teste"** — tratados como contratos first-class.
- **§5 Acceptance Criteria**: exigido *evidence pointer* (file:line OU test-name) por item; novo row-type `AMBIGUOUS` para critérios vagos (não falha sozinho).
- **Balance list estendida** — proibição explícita de "delete body de API pública sem substituto".
- **Seção Self-policy nova** — reviewer não pode introduzir `any`/`@ts-ignore`/empty-catch/PII-log/Math.random-security nos próprios fixes.
- **Fail-safe**: `ISSUES_FIXED` só incrementa quando verificação passou.
- **Processo**: passo 1 obrigatório `git diff --name-only` → diff-only scope.
- **Output**: bloco `---AGENT_RESULT---` obrigatoriamente como última saída.

### code-simplifier
- **Grep-before-extract obrigatório** — antes de aceitar qualquer helper novo no diff, grep `src/{utils,services,helpers,lib}` por nome + assinatura semântica.
- **Rule-of-3 expandida** — 5 rows na tabela DRY, incluindo: (a) 1–2× mantém duplicado; (b) 3+× com domínios/stakeholders independentes mantém duplicado; (c) mesma sintaxe com conceitos diferentes mantém duplicado.
- **Seção "NÃO-TOCAR"** — lista explícita (try/catch vazio, throw, `@ts-*` / `eslint-*` / TODO, empty-body como no-op proposital, código recém-tocado pelo reviewer).
- **Diff-only scope** como passo 1 obrigatório.
- **Fail-safe** simétrico ao reviewer.
- **Output**: `AGENT_RESULT` como última saída.

## 3. Deferred — itens que ficaram fora do quadrante (impacto ≥ Médio, conf = Alta)

| # | Origem | Descrição | Racional |
|---|---|---|---|
| R1-13 | R1 matrix | Guard explícito para "unknown-safe-replacement" (S3 eval) | Acabou sendo parcialmente coberto por "Deletar corpo de API pública sem substituto — REPORT". Se surgir evidência adicional, re-avaliar. |
| R1-14 | R1 matrix | Row-type `AC-AMBIGUOUS` no output | Aplicado implicitamente (§5 do reviewer). Sem ação extra. |
| R1-15 | R1 matrix | Clean-pass format para simplifier sem achados | Baixo impacto: simplifier já emite AGENT_RESULT com `ISSUES_FOUND=0` via contrato natural. |
| R1-16 | R1 matrix | Query de memória genérica ("config") | Baixo impacto; deixado como opcional. |
| R2-1 | R2 matrix | Explicitar `git diff {file}` content-read para behaviour-change | Opus 4.7 chama naturalmente; confidence média. |
| R2-2 | R2 matrix | Grep-before-extract aceitar convenções exóticas (`shared/`, `common/`) | Impacto baixo; projetos bem-comportados usam {utils,services,helpers,lib}. |
| R2-3 | R2 matrix | Sinal orchestrator ↔ simplifier sobre linhas tocadas pelo reviewer | Não factível no agente; recomendação orchestrator abaixo. |
| R3-1 | R3 matrix | Exemplar "Dodgy-Diff" (Meta 2026) no behaviour-change rule | Redundante; já coberto por lista de exemplos. |
| R3-2 | R3 matrix | Clarificar conditional "após reviewer" no item NÃO-TOCAR | Já conditionado pela redação atual. |

## 4. Recomendações para os orchestrators (fora do escopo do audit)

Registradas para `build-certify/SKILL.md` e `resolve-certify/SKILL.md`:

### R-ORCH-1 — TRIVIAL + non-security diff: ampliar trigger para tipagem
Hoje build-certify TRIVIAL invoca reviewer só quando o grep de palavras-chave de segurança dispara. Cenário T3 (`.d.ts` com return type faltando) passa batido. Sugestão: estender o trigger com patterns de tipagem (`any`, `@ts-ignore`, `.d.ts` modificado) — ou promover para STANDARD por heurística simples.

### R-ORCH-2 — STANDARD resolve-certify: considerar simplifier quando diff contiver sinais de clareza óbvios
C4 (comentado-out code) em diff STANDARD do resolve-certify fica sem simplifier. Pequeno custo executar simplifier em diffs ≤ N linhas mesmo em STANDARD; avaliar tradeoff.

### R-ORCH-3 — Ordem inversa reviewer↔simplifier entre os dois certifies
Build-certify (COMPLEX): reviewer → simplifier. Resolve-certify (COMPLEX): simplifier → reviewer. O audit confirmou que os agentes são robustos em ambas as ordens AGORA (o item M2 valida; NÃO-TOCAR protege o caminho simplifier-first). Mas mantenha a assimetria consciente — se for intencional (reviewer de /build detecta issues de spec-implementação primeiro; simplifier de /resolve pule o código legado antes do reviewer olhar as correções), documente no próprio SKILL.md para futuros mantenedores.

### R-ORCH-4 — Passar lista de arquivos tocados pelo reviewer para o simplifier
Na ordem R→S de build-certify COMPLEX, o orchestrator poderia passar ao simplifier: "arquivos que o reviewer modificou: X, Y" para ajudar o simplifier a respeitar o item NÃO-TOCAR "código que o reviewer tocou". Mudança pequena no orchestrator; alto valor na ordenação robusta.

### R-ORCH-5 — Re-verify after quality agents: contrato já existente (Iron Law) mantido
Ambos certifies já têm Step 2.5 "Post-Quality Verification". O novo Fail-safe dos agentes complementa esse mecanismo — se o agente não conseguiu verificar, reporta `ISSUES_FOUND` sem `ISSUES_FIXED`, e o orchestrator re-verify continua enforçando.

## 5. Princípios externos incorporados

Material consultado (todos pós-2025-10, com ênfase Opus 4.7 lançado 2026-04-16):

- **Opus 4.7 Best Practices (Claude.com, 2026-04-16)**: literalidade, intent explícito, verificação como alavanca de maior impacto. → Diff-only scope explícito, AC evidence pointer, Fail-safe.
- **Opus 4.7 Breaking Changes (keepmyprompts.com, 2026-04-17)**: "compensatory scaffolding is counterproductive." → Prompts mais enxutos onde possível; regras crisp.
- **Sub-agents doc (code.claude.com)**: "Design focused subagents — each excels at one specific task." → Boundary sharpening entre reviewer/simplifier.
- **Claude Code Best Practices (code.claude.com)**: "Address root causes, not symptoms" + verification é a maior alavanca. → Self-policy proibindo `@ts-ignore` / empty-catch como "fixes" no próprio reviewer.
- **State of AI Code Review 2025 (devtoolsacademy)**: FP < 5% ou a ferramenta é ignorada; escopo AI = "style, bugs, missing tests". → MÉDIO/BAIXO = report-only; confidence-rubric substituindo tamanho.
- **Rule of Three (Fowler/Roberts, understandlegacycode)**: knowledge duplication ≠ char duplication; evolução independente. → Rule-of-3 expandida.
- **OWASP Top-10 LLM 2025 + SAST-Genius/IRIS**: LLM code reviewers amplificam SAST com −91% FP / +104% detection. → Severity table inclui padrões concretos (SQL injection, Zod missing, TOCTOU).
- **Binary-checklist evaluation (LangChain/Patronus)**: pass/fail com evidência + provenance. → AC evidence pointer obrigatório.
- **Meta Dodgy Diff / intent-aware (InfoQ 2026-04)**: reframe de diff como semantic signal. → Behaviour-change-in-refactor como first-class rule.
- **Meta structured-prompting (VentureBeat 2026-04)**: estrutura aumenta acurácia → 93%. → Nossos prompts mantêm tabelas estruturadas + checklists literais.

## 6. Summary

Audit convergiu em 3 rodadas (1 de edição, 2 empty consecutivas). 12 fixes aplicados, 9 deferidos, 5 recomendações de orchestrator registradas. Contratos preservados (`AGENT_RESULT`, BLOCKING-semantics, frontmatter). Melhorias maiores: severity calibration (+2), scope discipline (+2), boundary respect (+2), fail-safe (+1-2), AC fidelity (+2), rule-of-3 (+2).

A maior alavanca foi **severity calibration** — o "Math.random = MÉDIO" era um falso negativo sistemático para código de auth, e "<10 linhas" como proxy de auto-fix subpatchava bugs complexos óbvios.

A maior rigidez ganha foi a **boundary** entre reviewer e simplifier — antes frágil em volta de error handling; agora blindada pela lista NÃO-TOCAR explícita.
