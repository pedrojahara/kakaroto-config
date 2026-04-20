# Round 1 — Impact × Confidence Matrix

Apply only rows where (Impacto ≥ Médio) AND (Confiança = Alta). Others → deferred.

| # | Agente | Eixo | Issue observada | Fix proposto | Impacto | Confiança | Aplicar? |
|---|---|---|---|---|---|---|---|
| 1 | R | Severity | Math.random() rotulado MÉDIO mesmo em auth/token/session | Substituir linha da tabela: "Math.random() em auth/token/session/CSRF/password-reset = CRÍTICO; demais usos de random = BAIXO". Adicionar hint no checklist de segurança. | Alto | Alta | **SIM** |
| 2 | R | Severity | "<10 linhas" como heurística para ALTO→fix é arbitrário e falha em S8 | Substituir por rubrica de confiança: "Fix ALTO quando (a) a causa-raiz é clara no próprio diff, (b) existe uma correção mecanicamente única, (c) tsc+testes verificam. Caso contrário: REPORT." | Alto | Alta | **SIM** |
| 3 | R+S | Scope | diff-only scope não é o primeiro passo obrigatório | Passo 1 MANDATORY: `git diff --name-only` → armazenar lista; proibir Edit/Read em arquivos fora da lista (exceto utils referenciados pelo diff). | Médio | Alta | **SIM** |
| 4 | S | DRY | Grep-before-extract/Grep-before-add-helper não enforçado | Adicionar regra: "Antes de aceitar qualquer função nova no diff, Grep `src/{utils,services,helpers,lib}` por nome E por assinatura semelhante. Se existe → substituir." Transformar em primeiro passo da análise DRY. | Médio | Alta | **SIM** |
| 5 | S | Rule-of-3 | Falta caveat de independent-evolution + knowledge-vs-char | Adicionar 2 linhas à tabela DRY: "3+ ocorrências mas domínios/stakeholders independentes → MANTER duplicado"; "Mesma sintaxe mas conceitos diferentes (e.g., validação de email vs URL) → MANTER duplicado". | Médio | Alta | **SIM** |
| 6 | S | Boundary | "Remover código comentado / dead code" pode ser lido incluindo try/catch vazio | Adicionar lista explícita de "NÃO tocar": blocos try/catch (mesmo vazios), handlers de erro, `throw`, comentários com `@ts-`/`eslint-`, `TODO/FIXME`. | Alto | Alta | **SIM** |
| 7 | R | Bugs | Behaviour-change-in-refactor não é checklist item | Adicionar ao "Bugs Óbvios": "Mudança de comportamento em refactor: quando o diff substitui corpo de função, compare semântica antes/depois; qualquer diferença observável não justificada no spec é BLOCKING." | Alto | Alta | **SIM** |
| 8 | R | Scope | Test files não são primeira-classe | Adicionar: "Arquivos de teste são contratos; todas as regras se aplicam (asserts corretos, sem `any`, sem skip silencioso). Exceção: apenas mock/fixture stubs podem relaxar tipagem." | Médio | Alta | **SIM** |
| 9 | R | AC | Evidence pointer não exigido | Atualizar seção AC: "cada critério = PASS apenas com pointer explícito (file:line OU nome-do-teste). Sem pointer = FAIL." Adicionar exemplo no output table. | Médio | Alta | **SIM** |
| 10 | R+S | Fail-safe | ISSUES_FIXED conta mesmo quando verificação foi pulada | Adicionar: "Se tsc ou npm run test falharam OU não puderam rodar (ex: .d.ts sem test runner), o item fica como FOUND, NÃO FIXED. STATUS só é PASS se todos os fixes foram verificados." | Médio | Alta | **SIM** |
| 11 | R+S | Contract | AGENT_RESULT deve ser final | Adicionar: "O bloco `---AGENT_RESULT---` é a ÚLTIMA saída; nada depois." | Médio | Alta | **SIM** |
| 12 | R | Self-policy | Auto-fix pode introduzir `any`/`@ts-ignore`/try-swallow | Adicionar seção "Fixes obedecem às mesmas regras": "Ao aplicar correção, você NÃO PODE introduzir `any`, `@ts-ignore`, `@ts-expect-error`, try/catch sem mensagem, console.log de PII. Se a correção exigiria isso → REPORT em vez de fix." | Alto | Alta | **SIM** |
| 13 | R | Scope | `unknown-safe-replacement` (caso S3): reviewer remove API sem substituto claro | Adicionar: "Se remover uma API chamada por outras partes, escrever como REPORT com sugestão de substituto; não deletar body." | Médio | Média | Deferred (aguardar evidência adicional) |
| 14 | R | AC | Output format para AC ambíguo | Adicionar row-type `AC-AMBIGUOUS` na tabela | Baixo | Média | Deferred |
| 15 | S | Output | Clean-pass output format | Adicionar "emit AGENT_RESULT mesmo se nada detectado" | Baixo | Alta | Deferred (baixo impacto) |
| 16 | R+S | Misc | `mcp__memory__search_nodes({query:"config"})` genérico | Remover ou tornar opcional | Baixo | Média | Deferred |

## Decisão Round 1

Aplicar: #1, #2, #3, #4, #5, #6, #7, #8, #9, #10, #11, #12 (total 12 fixes).
Deferred: #13, #14, #15, #16 (registrar para Round 2+ se evidência aparecer).
