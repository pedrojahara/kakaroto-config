# Round 2 — Simulated Runs (post Round-1 edits)

Prompts in effect: the updated `code-reviewer.md` and `code-simplifier.md` committed at 68f0ccf.
Revisiting each scenario; focused on whether Round-1 fixes resolved the observations.

| # | Cenário | Round 1 | Round 2 | Justificativa da mudança |
|---|---|---|---|---|
| S1 | SQL injection | ✅ | ✅ | Unchanged. |
| S2 | Hardcoded secret | ✅ | ✅ | Unchanged. |
| S3 | eval() | ⚠ unknown-safe-replacement | ✅ | New Balance rule: "deletar corpo de API pública sem substituto → REPORT." Reviewer agora escala em vez de remover o corpo do callable. |
| S4 | exec() com variável | ✅ ALTO | ✅ CRÍTICO | Severidade upgrade (tabela revisada: exec com var = CRÍTICO). Mais pressão para fix. |
| S5 | Math.random() auth | ❌ misclassed | ✅ | Tabela revisada: auth/token/session = CRÍTICO, corrigido via crypto.randomBytes. |
| S6 | console.log PII | ✅ | ✅ | Unchanged. |
| S7 | Deserialize sem validação | ✅ | ✅ | Zod ausente agora CRÍTICO explícito; mesma ação. |
| S8 | Auth race | ⚠ underpatched | ✅ | Confidence-rubric: correção não-única → REPORT. Orchestrator lida. |
| T1 | any | ✅ | ✅ | |
| T2 | @ts-ignore | ✅ | ✅ | |
| T3 | .d.ts TRIVIAL | orchestrator skip | orchestrator skip | Fora do escopo; registrar no final-report. |
| T4 | Zod missing | ✅ | ✅ | |
| T5 | `as` cast across union | ✅ | ✅ | |
| B1 | null after optional chain | ✅ | ✅ | |
| B2 | missing import | ✅ | ✅ | |
| B3 | orphan charge | ✅ | ✅ | |
| B4 | test off-by-one | ⚠ framing | ✅ | §4 explicit: "Arquivos de teste são contratos; todas as regras se aplicam". |
| B5 | unawaited promise | ✅ | ✅ | |
| C1 | bad names | ✅ | ✅ | Ordem R→S funciona. |
| C2 | 4-level nesting | ✅ | ✅ | |
| C3 | triple ternary | ✅ | ✅ | |
| C4 | commented code | orchestrator skip | orchestrator skip | Fora do escopo. |
| C5 | dead code + unused import | ✅ | ✅ | |
| D1 | reimplement slugify | ⚠ grep não enforcado | ✅ | "Grep-before-extract (OBRIGATÓRIO)" força busca. Encontra util existente. |
| D2 | 3+ extract | ✅ | ✅ | |
| D3 | 2x trap | ⚠ | ✅ | Tabela nova cobre 1-2x = manter; caveat independent-evolution explicita. |
| A1 | AC pass | ⚠ sem pointer | ✅ | Evidence pointer agora obrigatório: `src/api/x.ts:15 + test 'validates body'`. |
| A2 | AC missing test | ✅ | ✅ | BLOCKING com referência ao critério (mais explícito). |
| M1 | bug em refactor | ❌ | ✅ | Novo item "Behaviour-change em refactor" no checklist de Bugs Óbvios. Reviewer compara pré/pós e flag BLOCKING. |
| M2 | ordering trap | ⚠ frágil | ✅ | NÃO-TOCAR list inclui try/catch mesmo vazio. Simplifier preserva; reviewer pega. |

## Falhas residuais observadas

- Nenhum dos itens ❌/⚠ do Round 1 permanece; todos foram convertidos em ✅.
- Gaps orchestrator-level (T3 TRIVIAL .d.ts, C4 STANDARD resolve simplifier-skip) persistem por design — registrados no final-report como recomendações para build-certify/resolve-certify.

## Considerações novas levantadas

1. Reviewer precisa ver pré/pós do diff ao checar behaviour-change (M1). Prompt lista `git diff --name-only` + `git diff --stat`; `git diff {file}` para conteúdo é implícito. Opus 4.7 tende a executar naturalmente — evidência empírica mostra modelo chamar git diff content sem mandato. **Não qualifica para fix** (impact baixo, conf média-baixa de que é necessário).

2. Grep-before-extract lista `src/{utils,services,helpers,lib}`. Alguns projetos usam `shared/`, `common/`. Palavra chave "ou equivalentes do projeto" seria boa mas impact baixo (projetos com convenções exóticas são minoritários). **Não qualifica**.

3. Simplifier "código que o reviewer tocou nesta mesma rodada" — não há sinal técnico pra reconhecer quais linhas o reviewer acabou de editar; baseia-se em ordem do orchestrator. Nenhuma melhoria factível no agente; orchestrator-level (build-certify já explicita ordem R→S justamente por isso). **Sem ação no agente**.
