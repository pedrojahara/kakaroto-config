# Fase 5: Commit & Push

## Contexto
Bug resolvido, verify passou. Commitar e fazer push de forma AUTONOMA.

---

## Passo 1: Verificar Mudancas

```bash
git status
```

**Se nao houver mudancas:** Reportar "Nada a commitar" → FIM

---

## Passo 2: Commit

```bash
git add -A
git commit -m "$(cat <<'EOF'
fix: {descricao do bug resolvido em ingles}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

**Sempre prefixo `fix:`** - workflow e de debug.

---

## Passo 3: Push

```bash
git push
```

**Se falhar:** Reportar erro ao user.

---

## Passo 4: Checkpoint Final

```javascript
TodoWrite({
  todos: [
    { content: "Reproduce: bug reproduzido", status: "completed", activeForm: "Bug reproduced" },
    { content: "Investigate: causa raiz identificada", status: "completed", activeForm: "Root cause identified" },
    { content: "Fix: correcao implementada", status: "completed", activeForm: "Fix implemented" },
    { content: "Verify: quality gates passando", status: "completed", activeForm: "Quality gates passed" },
    { content: "Commit: commitado e pushed", status: "completed", activeForm: "Committed and pushed" }
  ]
})
```

---

## Passo 5: Confirmar

```bash
git log --oneline -1
```

Reportar ao user: fix commitado e pushed.

---

## Regras

1. **1 fix = 1 commit**
2. **Sempre `fix:` como prefixo**
3. **Mensagem em ingles**
4. **NUNCA** --force push
5. **NUNCA** commitar se verify falhou
