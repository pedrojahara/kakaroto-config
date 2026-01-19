# Fase 6: Quality

## Responsabilidade
REFACTOR do ciclo TDD + Quality Gate.

---

## Passo 1: Refactoring Agents

### 1.1 Code Simplifier
```javascript
Task({
  subagent_type: "code-simplifier",
  prompt: `Verificar reuso (DRY). Detectar duplicacoes. Simplificar.

REGRA PARA .test.ts - FACTORIES:
- SE objetos inline representando entidades
- E factory existe em test-utils/factories/
- ENTAO substituir por factory
- Validar com npm test
- Reverter se falhar`,
  description: "Simplify and DRY check"
})
```

### 1.2 Code Reviewer
```javascript
Task({
  subagent_type: "code-reviewer",
  prompt: "Review final. Verificar qualidade, seguranca, patterns. Corrigir issues.",
  description: "Final code review"
})
```

---

## Passo 2: Verificar Testes Pos-Refactoring

```bash
npm test 2>&1
```

| Resultado | Acao |
|-----------|------|
| Todos passam | Pular para Passo 3 (Final Gate) |
| Algum falhou | Executar Recovery |

### Recovery (SE FAIL)

1. Identificar causa
2. Verificar diff do agent
3. Decidir: reverter ou corrigir
4. Re-run
5. Max 2 tentativas

---

## Passo 3: Final Gate

```bash
npm test && npx tsc --noEmit && npm run build
```

### Self-Healing Loop

```
tentativas = 0
while (gate falhando AND tentativas < 2):
    1. Identificar erro
    2. Analisar causa
    3. Corrigir
    4. Re-run
    tentativas++
```

---

## Gate (BLOQUEANTE)

```bash
# Testes passam
npm test || { echo "❌ Testes falhando"; exit 1; }

# TypeScript compila
npx tsc --noEmit || { echo "❌ TypeScript não compila"; exit 1; }

# Build funciona
npm run build || { echo "❌ Build falhou"; exit 1; }

echo "✅ Gate 06-quality passou"
```

---

## Passo 4: Atualizar Estado

```bash
jq '
  .currentPhase = "07-validation" |
  .completedPhases += ["06-quality"] |
  .resumeHint = "Quality completo. Prox: E2E validation" |
  .lastStep = "Passo 4: Atualizar Estado"
' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
```

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/07-validation.md
