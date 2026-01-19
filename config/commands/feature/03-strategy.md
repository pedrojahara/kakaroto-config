# Fase 3: Strategy

## Responsabilidade
Aprovar estrategia de testes. **UNICA APROVACAO** do workflow.

---

## Passo 1: Carregar Inputs

### 1.1 Criterios do User (01-understand)
```
Read .claude/interviews/${SLUG}.md → secao "## Criterios de Aceite do User"
```

### 1.2 Cenarios Tecnicos (02-analyze)
```
Read .claude/analysis/${SLUG}.md → secao "## Cenarios Tecnicos Descobertos"
```

### 1.3 Tipo da Feature
```
Read .claude/workflow-state.json → campo "featureType" (api/ui/service/job)
```

> **Razao:** Garante que dados estao em contexto antes de qualquer processamento.

---

## Passo 2: Transformar Criterios do User

Converter criterios em cenarios testaveis:

| Criterio User | Cenario Derivado | Tipo |
|---------------|------------------|------|
| "funciona se X" | "X acontece" | SUCESSO |
| "falha se Y" | "Y nao acontece" | FALHA |

> **Razao:** Normaliza linguagem do user para linguagem de teste.

---

## Passo 3: Complementar com Failure Analysis

```
Read ~/.claude/techniques/failure-analysis.md
```

Executar APENAS para categorias NAO cobertas por interview + analysis.
Budget: max 3-5 cenarios ADICIONAIS.

> **Razao:** Pega edge cases que user e analise tecnica podem ter perdido.

---

## Passo 4: Opcoes de Validacao E2E

Baseado no tipo da feature, identificar opcoes viaveis:

| Tipo Feature | E2E Padrao | Alternativa |
|--------------|------------|-------------|
| ui | Playwright (auto) | hybrid |
| api | API script (semi-auto) | hybrid |
| service | Integration test (auto) | hybrid |
| job | hybrid | semi-auto |

Registrar:
- **Opcao recomendada:** {tipo}
- **Opcoes alternativas:** {lista}
- **Custo/beneficio de cada:** {breve}

> **Razao:** ST precisa conhecer opcoes E2E para decidir se vale incluir.
> Ver: `~/.claude/commands/feature/playbooks/_e2e-base.md` + `playbooks/{tipo}/e2e.md`

---

## Passo 5: Tabela Unificada de Cenarios

Consolidar TODOS os cenarios com fonte e score:

| # | Cenario | Fonte | Nivel | Score | Decisao |
|---|---------|-------|-------|-------|---------|
| U1 | "{do user}" | interview | Integration | - | TESTAR |
| T1 | "{do codigo}" | analysis | Unit | {PxI} | ? |
| FA1 | "{failure analysis}" | technique | Unit | {PxI} | ? |
| E2E1 | "{fluxo completo}" | e2e-option | E2E | - | ? |

**Coluna Nivel:** Unit | Integration | E2E
**Coluna Decisao:** Preenchida no Passo 6 (ST)

**Regras:**
- Fonte "interview" → SEMPRE TESTAR (criterio do user)
- Fonte "analysis/technique" → Aplicar P×I (Score >= 6 = TESTAR)
- Fonte "e2e-option" → Decidido no Passo 6

> **Razao:** Visao completa de TODAS as opcoes de teste antes da reflexao.

---

## Passo 6: Reflexao e Decisao (ST)

Usar `mcp__sequential-thinking__sequentialthinking`:

1. **Inventario completo** - Quantos cenarios tenho? De que fontes?
2. **Cobertura por nivel** - Quantos Unit vs Integration vs E2E?
3. **Criterios do user** - Todos estao cobertos? Como?
4. **Cenarios tecnicos** - Quais tem Score >= 6? Quais < 6?
5. **E2E vale a pena?** - Custo vs beneficio para esta feature
6. **Decisao final** - Para cada cenario: TESTAR ou NAO TESTAR
7. **Justificativa** - Por que cada decisao? Mitigacao para excluidos?

`totalThoughts`: 7

**Output:** Tabela Unificada com coluna "Decisao" preenchida

> **Razao:** ST agora tem TODOS os dados para decidir estrategia completa.

---

## Passo 7: Montar Proposta Unica

Apresentar decisao consolidada:

```markdown
### Testes que serao implementados

| # | Cenario | Fonte | Nivel | Teste |
|---|---------|-------|-------|-------|
| U1 | "{criterio user}" | interview | Integration | `it('...')` |
| T1 | "{cenario tecnico}" | analysis | Unit | `it('...')` |
| E2E1 | "{fluxo completo}" | e2e-option | E2E | `test('...')` |

### Cenarios NAO testados (com justificativa)

| # | Cenario | Score | Justificativa | Mitigacao | Arquivo |
|---|---------|-------|---------------|-----------|---------|
| FA2 | "{edge case}" | 4 | Baixa probabilidade | try/catch | handler.ts:45 |

### E2E Validation Spec

**Tipo:** {auto | semi-auto | hybrid}

{SE auto}
**Script/Ferramenta:** {playwright | functional-validator | integration test}
**Cenario:** {Given/When/Then}
**Comando:** `{npm run test:e2e ou similar}`

{SE semi-auto}
**Trigger:** {POST /api/endpoint ou comando}
**Verificacoes do Claude:**
- [ ] Response status/body esperado
- [ ] Query DB: `{collection}.where(...)`
- [ ] Verificar logs: `grep "{pattern}"`

{SE hybrid}
**Acao do User:**
- [ ] {descricao detalhada do que user deve fazer}

**Verificacoes do Claude:**
- [ ] Query DB: `{collection/table}.where(...)`
- [ ] Verificar logs: `grep "{pattern}"`
- [ ] Confirmar side effect: `GET /api/{endpoint}`

**Criterio de Sucesso:**
- [ ] {condicao verificavel}

### Resumo da Estrategia

- **Unit tests:** {N} cenarios
- **Integration tests:** {N} cenarios
- **E2E:** {SIM/NAO} - {justificativa}
- **Cobertura dos criterios do user:** 100%
```

> **Razao:** User ve proposta unica e completa, nao fragmentada.

---

## Passo 8: Aprovacao (AUQ)

```javascript
AskUserQuestion({
  questions: [{
    question: "Esses testes cobrem suas necessidades?",
    header: "Aprovacao",
    options: [
      { label: "Sim, cobrem", description: "Prosseguir com implementacao autonoma" },
      { label: "Falta cenario", description: "Vou descrever o que falta" },
      { label: "Mudar E2E", description: "Quero mudar a estrategia E2E" },
      { label: "Mudar tipo", description: "Prefiro outro tipo de teste" }
    ],
    multiSelect: false
  }]
})
```

### SE "Falta cenario" ou "Mudar tipo":
1. Coletar feedback
2. Ajustar proposta
3. Repetir aprovacao

### SE "Mudar E2E":
1. Apresentar alternativas E2E do Passo 4
2. Ajustar spec E2E
3. Confirmar e prosseguir

---

## Passo 9: Gerar Contract Lock

Apos aprovacao, gerar contrato IMUTAVEL.

### 9.1 Salvar Contract
```
Write .claude/contracts/{slug}.md
```

### 9.2 Formato
```markdown
# Contract: {feature}

**Status:** LOCKED
**Aprovado em:** {YYYY-MM-DD HH:MM}

## Cenarios de Falha (Brainstorm)

| # | Cenario | Categoria | P | I | Score | Decisao |
|---|---------|-----------|---|---|-------|---------|
| 1 | {cenario} | INPUT | Alta | Alto | 9 | TESTAR |
| 2 | {cenario} | DEPENDENCY | Média | Alto | 6 | TESTAR |
| 3 | {cenario} | STATE | Baixa | Alto | 3 | MITIGAR |

## Criterios Aprovados (Testes)

| # | Criterio | Fonte | Nivel | Cenario Ref | Teste | Status |
|---|----------|-------|-------|-------------|-------|--------|
| 1 | "[criterio do user]" | interview | Integration | - | `it('...')` | LOCKED |
| 2 | "[cenario tecnico]" | analysis | Unit | #T1 | `it('...')` | LOCKED |

## Cenarios Excluidos (com Justificativa)

| # | Cenario Ref | Score | Por que NAO testar | Mitigacao | Arquivo |
|---|-------------|-------|--------------------|-----------|---------|
| 3 | #3 | 3 | {justificativa} | {mitigacao} | {arquivo:linha} |

## E2E Validation

**Tipo:** {auto | semi-auto | hybrid}
**Status:** PENDING

{spec completa conforme Passo 7}

## IMUTABILIDADE

> Mudanca de escopo requer nova aprovacao e re-geracao do contract.
```

---

## Gate (BLOQUEANTE)

```bash
SLUG=$(jq -r '.feature' .claude/workflow-state.json 2>/dev/null)

# Pré-condições
test -f ".claude/interviews/${SLUG}.md" || { echo "❌ Pré: interview não existe"; exit 1; }
test -f ".claude/analysis/${SLUG}.md" || { echo "❌ Pré: analysis não existe"; exit 1; }

# Pós-condição: Contract
test -f ".claude/contracts/${SLUG}.md" || { echo "❌ Contract não encontrado: .claude/contracts/${SLUG}.md"; exit 1; }
grep -q "## Criterios Aprovados" ".claude/contracts/${SLUG}.md" || { echo "❌ Contract sem critérios aprovados"; exit 1; }
grep -q "## E2E Validation" ".claude/contracts/${SLUG}.md" || { echo "❌ Contract sem E2E Validation spec"; exit 1; }
grep -q "**Status:** LOCKED" ".claude/contracts/${SLUG}.md" || { echo "❌ Contract não está LOCKED"; exit 1; }

echo "✅ Gate 03-strategy passou"
```

**IMPORTANTE:** Esta é a ÚNICA parada do workflow. Após aqui, execução é AUTÔNOMA.

---

## Passo 10: Atualizar Estado do Workflow

```bash
if command -v jq &> /dev/null; then
  jq '
    .currentPhase = "04-red" |
    .completedPhases += ["03-strategy"] |
    .resumeHint = "Testes APROVADOS. Prox: escrever testes RED, executar autonomamente" |
    .lastStep = "Passo 10: Atualizar Estado" |
    .contract = (".claude/contracts/" + .feature + ".md")
  ' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
else
  echo "Atualizar .claude/workflow-state.json: currentPhase=04-red, add 03-strategy to completedPhases"
fi
```

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/04-red.md
