# Fase 8: Delivery

## Responsabilidade
Entregar código validado (commit + push + memory sync).

---

## Passo 1: Verificar Estado

```bash
git status
git diff --stat
```

---

## Passo 2: Commit

```bash
git add -A
git commit -m "$(cat <<'EOF'
{type}: {descricao concisa em ingles}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

**Tipos:** feat, fix, refactor, docs, test

---

## Passo 3: Push

```bash
git push
```

---

## Passo 4: Memory Sync

```javascript
Task({
  subagent_type: "memory-sync",
  prompt: "Sincronizar knowledge graph. Skip se trivial.",
  description: "Sync memory graph"
})
```

---

## Gate (BLOQUEANTE)

```bash
# 1. Commit deve existir com formato válido
git log -1 --format="%s" | grep -qE "^(feat|fix|refactor|test|docs):" || {
  echo "❌ GATE BLOQUEADO: Commit não criado ou formato inválido"
  exit 1
}

# 2. Push deve estar feito (branch remota atualizada)
git status | grep -q "Your branch is up to date\|nothing to commit" || {
  echo "⚠️ AVISO: Mudanças locais não pushadas"
}

echo "✅ Gate 08-delivery passou"
```

---

## Passo 5: Atualizar Estado

```bash
jq '
  .currentPhase = "09-evaluate" |
  .completedPhases += ["08-delivery"] |
  .resumeHint = "Feature entregue. Prox: auto-avaliacao do workflow" |
  .lastStep = "Passo 5: Atualizar Estado"
' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
```

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/09-evaluate.md
