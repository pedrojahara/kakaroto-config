# Fase 4: RED (Escrever Testes)

> **REGRA:** Testes devem FALHAR. Imports inexistentes OK. NÃO escreva código de produção.

## Responsabilidade
Escrever testes que FALHAM baseados no contract. Execução AUTÔNOMA.

---

## Passo 1: Carregar Contexto

```
Read {state.contract}   # Critérios aprovados + mitigações
Read {state.analysis}   # Mapa: testes existentes, código a reutilizar
```

Listar factories/mocks disponíveis:
- test-utils/factories/ → nomes
- test-utils/mocks/ → nomes

---

## Passo 2: Isolar Contexto (CRUCIAL)

**DESCARTAR da memória:**
- Código de produção
- Patterns de implementação
- Como funções são implementadas

**RETER apenas:**
- Critérios do contract (O QUE testar)
- Nomes de factories/mocks (COMO isolar)
- Mapa de testes existentes (ONDE colocar)

> **Objetivo:** Testar COMPORTAMENTO, não IMPLEMENTAÇÃO.

---

## Passo 3: Escrever Testes

### 3.1 Decisão de Local

| Resultado no Analysis | Ação |
|----------------------|------|
| Teste existe para módulo | ESTENDER arquivo existente |
| Arquivo existe, caso não | ADICIONAR describe/it |
| Nenhum existe | CRIAR novo arquivo |

### 3.2 Estrutura (via Playbook)

Carregar playbook de testes conforme tipo da feature:

```
Read ~/.claude/commands/feature/playbooks/{featureType}/red.md
```

| featureType | Playbook |
|-------------|----------|
| api | playbooks/api/red.md |
| ui | playbooks/ui/red.md |
| service | playbooks/service/red.md |
| job | playbooks/job/red.md |

O playbook define:
- Testes requeridos (Unit/Integration/E2E)
- Mocks tipicos
- Test patterns com vitest

### 3.3 Regras

- Imports inexistentes OK (vão falhar - RED)
- Usar factories de test-utils/factories/
- Usar mocks de test-utils/mocks/
- 1 critério do contract → 1+ testes
- **APENAS Unit e Integration tests** (E2E é validado em 07-validation)

---

## Passo 4: Sufficiency Gate

Usar `mcp__sequential-thinking__sequentialthinking`:

Verificar apenas critérios Unit/Integration (E2E é separado):

| # | Critério (Unit/Integration) | Teste Escrito | Coberto? |
|---|----------------------------|---------------|----------|
| 1 | "{critério}" | it('...') | ✓/✗ |

**SE** cobertura < 100%:
- Identificar critérios faltantes
- Voltar ao Passo 3
- Adicionar testes

**SE** cobertura == 100%:
- Prosseguir

---

## Passo 5: Verificar RED

```bash
npm test -- --testPathPattern="[feature]" 2>&1 || true
```

| Resultado | Ação |
|-----------|------|
| Todos FALHAM | Correto - prosseguir |
| Alguns passam | Investigar (já existe implementação?) |
| Erro de sintaxe | Corrigir teste e re-run |

---

## Passo 6: Commit RED

```bash
git add -A
git commit -m "$(cat <<'EOF'
test: add tests for [feature] (RED)

Tests expected to fail - implementation pending.
Coverage: {N} criteria from contract.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Gate (BLOQUEANTE)

```bash
SLUG=$(jq -r '.feature' .claude/workflow-state.json 2>/dev/null)

# Pré-condição
test -f ".claude/contracts/${SLUG}.md" || { echo "❌ Pré: contract não existe"; exit 1; }

# Pós-condição: Commit RED existe
git log -1 --format="%s" | grep -q "test:.*RED" || { echo "❌ Commit RED não encontrado"; exit 1; }

echo "✅ Gate 04-red passou"
```

---

## Passo 7: Atualizar Estado

```bash
jq '
  .currentPhase = "05-green" |
  .completedPhases += ["04-red"] |
  .resumeHint = "Testes RED commitados. Prox: implementar código mínimo" |
  .lastStep = "Passo 7: Atualizar Estado"
' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
```

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/05-green.md
