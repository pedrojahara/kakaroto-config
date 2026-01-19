# Fase 9: Evaluate

## Responsabilidade
Auto-avaliacao do workflow e propor melhorias.

---

## Passo 1: Coletar Metricas

```bash
git diff --stat HEAD~1
git log -1 --format="%s"
```

---

## Passo 2: Sequential Thinking #1 - DIAGNOSTICO

Usar `mcp__sequential-thinking__sequentialthinking`:

| Criterio | Peso | Como Medir |
|----------|------|------------|
| Completude | 40% | Todos itens implementados? |
| Qualidade | 20% | Review passou limpo? |
| Testes | 15% | Cobertura adequada? |
| Build | 10% | Passou na primeira? |
| Autonomia | 10% | Quantas perguntas? (ideal <=1) |
| Docs | 5% | Spec reflete implementacao? |

Para criterios < 80%: Aplicar 5 Whys

`totalThoughts`: 5-7

---

## Passo 3: Sequential Thinking #2 - SINTESE

Para cada problema identificado:

1. Tipo de mudanca? (Config/Skill/Pattern)
2. Qual arquivo editar?
3. Diff exato?
4. Efeitos colaterais?
5. Prioridade?

`totalThoughts`: 3-5

---

## Passo 4: Propor Melhorias (AUQ)

Para melhorias identificadas (max 3):

```javascript
AskUserQuestion({
  questions: [{
    question: "Detectei: {problema}. Causa: {causa}. Sugiro: {diff}. Aplicar?",
    header: "Melhoria",
    options: [
      { label: "Aplicar", description: "Editar arquivo" },
      { label: "Ignorar", description: "Pular desta vez" },
      { label: "Nunca sugerir", description: "Adicionar excecao" }
    ],
    multiSelect: false
  }]
})
```

**Acoes:**
- **Aplicar:** Edit tool
- **Ignorar:** Prosseguir
- **Nunca sugerir:** Adicionar em evaluation-exceptions.json

---

## Passo 5: Relatorio Final

```markdown
## Workflow Completo

**Score Final:** X%
- Completude: X%
- Qualidade: X%
- Testes: X%
- Build: X%
- Autonomia: X%

**Commit:** {hash} {message}

**Melhorias Aplicadas:** N
- [lista]

**Workflow /feature concluido.**
```

---

## Gate (BLOQUEANTE)

```bash
# Verificar que commit existe
git log -1 --format="%s" | grep -qE "^(feat|fix|refactor|test|docs):" || { echo "❌ Commit não encontrado"; exit 1; }

# Verificar E2E foi executado (no contract)
SLUG=$(jq -r '.feature' .claude/workflow-state.json 2>/dev/null)
grep -qE "Status:.*(PASSED|FAILED)" ".claude/contracts/${SLUG}.md" 2>/dev/null || { echo "❌ E2E não executado"; exit 1; }

echo "✅ Gate 09-evaluate passou"
```

---

## Passo 6: Finalizar Estado do Workflow

```bash
if command -v jq &> /dev/null; then
  jq '
    .currentPhase = "COMPLETED" |
    .completedPhases += ["09-evaluate"] |
    .completedAt = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" |
    .resumeHint = "Workflow COMPLETO. Nenhuma acao necessaria." |
    .lastStep = "Passo 6: Finalizar Estado"
  ' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
else
  echo "Atualizar .claude/workflow-state.json: currentPhase=COMPLETED, all phases complete"
fi

echo "✅ Workflow /feature COMPLETO"
cat .claude/workflow-state.json
```

### Arquivar State File (Opcional)

```bash
# Mover para histórico após conclusão bem-sucedida
FEATURE_SLUG=$(jq -r '.feature' .claude/workflow-state.json)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p .claude/workflow-history
mv .claude/workflow-state.json ".claude/workflow-history/${FEATURE_SLUG}-${TIMESTAMP}.json"
```
