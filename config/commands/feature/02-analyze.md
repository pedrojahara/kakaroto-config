# Fase 2: Analyze

## Responsabilidade
Explorar codebase e determinar estrategia de teste. Fase INTERNA (sem interacao com user).

---

## Passo 1: Triage de Tipo

Analisar feature e classificar:

| Keyword | Tipo | Playbook |
|---------|------|----------|
| endpoint, handler, route, API | api | playbooks/api/ |
| component, page, form, modal, hook | ui | playbooks/ui/ |
| service, util, transform, validate | service | playbooks/service/ |
| cron, job, scheduler, executor | job | playbooks/job/ |

**SE multiplos tipos:** Escolher o DOMINANTE (onde maior parte do codigo ficara).

---

## Passo 2: Carregar Playbook

```
Read ~/.claude/commands/feature/playbooks/{tipo}/analyze.md
```

O playbook define:
- Onde codigo fica
- Pattern de producao
- Criterios de testabilidade

---

## Passo 3: Buscar Codigo Existente

### 3.1 Patterns Similares
```
Grep: termos em {localizacao-do-playbook}/
```

### 3.2 Codigo Reutilizavel
| Necessidade | Codigo Existente | Acao |
|-------------|------------------|------|
| [o que precisa] | [arquivo:linha] | Reutilizar/Estender/Criar |

---

## Passo 4: Mapear Mocks

### 4.1 Consultar Existentes
```
Read test-utils/mocks/README.md
```

### 4.2 Verificar Disponibilidade
| Servico | Mock Existe? | Acao |
|---------|--------------|------|
| Database | Verificar | - |
| [externo] | Verificar | Criar se necessario |

---

## Passo 5: Avaliar Testabilidade

Baseado no playbook carregado:

| Tipo Teste | Requerido? | Motivo |
|------------|------------|--------|
| Unit | {do playbook} | {motivo} |
| Integration | {do playbook} | {motivo} |
| E2E | {do playbook} | {motivo} |

---

## Passo 6: Cenarios Tecnicos Descobertos

Baseado na exploracao (Passos 3-5), identificar cenarios de falha EVIDENTES no codigo.

### 6.1 Analise do Codigo Existente

Para cada dependencia/input encontrado, verificar:
- Existe tratamento de erro? (try/catch, .catch, fallback)
- Existe validacao? (Zod, type guards)
- Existe retry/circuit breaker?

### 6.2 Documentar Cenarios

| # | Cenario | Categoria | Fonte | Tratado? |
|---|---------|-----------|-------|----------|
| T1 | {cenario evidente} | {INPUT/DEPENDENCY/STATE} | {arquivo:linha} | Sim/Nao |

**Categorias**: INPUT, DEPENDENCY, STATE, ENVIRONMENT

> **Regra:** Documentar APENAS cenarios EVIDENTES do codigo.

---

## Passo 7: Persistir Analise

### 7.1 Salvar
```
Write .claude/analysis/{slug}.md
```

### 7.2 Formato
```markdown
# Analise: {feature}

## Metadata
- **Tipo:** {api/ui/service/job}
- **Playbook:** {arquivo}

## Mocks Mapeados
| Servico | Existe? | Acao |
|---------|---------|------|

## Testes Existentes
| Pattern | Arquivos |
|---------|----------|

## Cenarios Tecnicos Descobertos
| # | Cenario | Categoria | Fonte | Tratado? |
|---|---------|-----------|-------|----------|
```

---

## Gate (BLOQUEANTE)

```bash
SLUG=$(jq -r '.feature' .claude/workflow-state.json 2>/dev/null)

# Pré-condição
test -f ".claude/interviews/${SLUG}.md" || { echo "❌ Pré-condição falhou: interview não existe"; exit 1; }

# Pós-condição
test -f ".claude/analysis/${SLUG}.md" || { echo "❌ Análise não encontrada: .claude/analysis/${SLUG}.md"; exit 1; }
grep -q "## Metadata" ".claude/analysis/${SLUG}.md" || { echo "❌ Análise incompleta (falta Metadata)"; exit 1; }

echo "✅ Gate 02-analyze passou"
```

**Nota:** Esta fase NAO para. Execução automática para 03-strategy.

---

## Passo 8: Atualizar Estado do Workflow

```bash
if command -v jq &> /dev/null; then
  jq '
    .currentPhase = "03-strategy" |
    .completedPhases += ["02-analyze"] |
    .resumeHint = "Analise completa. Prox: apresentar testes propostos para aprovacao (UNICA parada)" |
    .lastStep = "Passo 8: Atualizar Estado" |
    .analysis = (".claude/analysis/" + .feature + ".md")
  ' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
else
  echo "Atualizar .claude/workflow-state.json: currentPhase=03-strategy, add 02-analyze to completedPhases"
fi
```

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/03-strategy.md
