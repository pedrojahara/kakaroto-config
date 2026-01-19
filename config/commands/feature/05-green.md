# Fase 5: GREEN (Implementar)

> **REGRA:** Código MÍNIMO para testes passarem. Sem validações extras, abstrações ou otimizações.

## Responsabilidade
Implementar código MÍNIMO para testes passarem. Execução AUTÔNOMA.

---

## Passo 1: Carregar Contexto

```bash
# Testes que falharam
git diff HEAD~1 --name-only | grep "\.test\.ts$"
```

```
Read {state.analysis}   # Código existente a reutilizar
Read {state.contract}   # Mitigações acordadas
```

---

## Passo 2: Planejar Tarefas

### 2.1 Mapear Testes → Código

| Teste | Código Necessário | Reutiliza? | Arquivo |
|-------|-------------------|------------|---------|
| it('A') | função X | helper.ts:20 | ESTENDER |
| it('B') | função Y | - | CRIAR |
| it('C') | função Z | utils.ts | REUTILIZAR |

### 2.2 Incluir Mitigações

Do contract, seção "Cenários Excluídos":

| Mitigação | Implementação | Arquivo |
|-----------|---------------|---------|
| try/catch para API | wrap em try/catch + log | handler.ts |
| Schema validation | zod schema | types.ts |

### 2.3 Ordenar

1. Dependências primeiro (tipos, utils)
2. Funções principais
3. Mitigações

---

## Passo 3: Implementar (Loop por Teste)

Para cada teste falhando:

```
┌─────────────────────────────────────────┐
│  1. TodoWrite: marcar in_progress       │
│  2. Implementar código MÍNIMO           │
│  3. tsc --noEmit                        │
│  4. npm test -- --testPathPattern="X"   │
│  5. SE passou → TodoWrite: completed    │
│     SE falhou → corrigir (max 3x)       │
│  6. Próximo teste                       │
└─────────────────────────────────────────┘
```

### O que é "Código Mínimo"?

**FAZER:**
- Exatamente o que teste espera
- Estruturas simples e elegantes
- Reutilizar código existente

**NÃO FAZER:**
- Validações além do testado
- Abstrações "por precaução"
- Otimizações prematuras
- Refactoring (fase 6)

---

## Passo 4: Validar GREEN

### 4.1 Testes

```bash
npm test
```

### 4.2 TypeScript

```bash
npx tsc --noEmit
```

### 4.3 Mitigações

Checklist do contract:
- [ ] Todas mitigações implementadas?
- [ ] Logging para cenários não testados?
- [ ] Schemas validam inputs de risco?

### 4.4 Loop de Correção

```
while (falhas AND tentativas < 3):
    Identificar erro
    Corrigir CÓDIGO (não teste)
    Re-run
    tentativas++

if ainda falha:
    PARAR e reportar ao user
```

---

## Passo 5: Commit GREEN

```bash
git add -A
git commit -m "$(cat <<'EOF'
feat: implement [feature]

- All tests passing
- Mitigations implemented

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Gate (BLOQUEANTE)

```bash
# Testes passam
npm test || { echo "❌ Testes falhando"; exit 1; }

# TypeScript compila
npx tsc --noEmit || { echo "❌ TypeScript não compila"; exit 1; }

echo "✅ Gate 05-green passou"
```

---

## Output

```markdown
## GREEN Phase - Completo

**Testes:** X/X passando

**Arquivos modificados:**
- [lista]

**Mitigações implementadas:**
- [lista]
```

---

## Passo 6: Atualizar Estado

```bash
jq '
  .currentPhase = "06-quality" |
  .completedPhases += ["05-green"] |
  .resumeHint = "GREEN completo. Prox: quality gate (refactoring)" |
  .lastStep = "Passo 6: Atualizar Estado"
' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
```

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/06-quality.md
