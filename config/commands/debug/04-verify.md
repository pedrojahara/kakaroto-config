# Fase 4: Verify

## Contexto
Fix implementado. Verificar e finalizar de forma AUTONOMA.

---

## Passo 1: Quality Gates

Rodar em sequencia:
```bash
npm test
npx tsc --noEmit
npm run build
```

**Se falhar:** Corrigir e rodar novamente. Nao prosseguir ate passar.

---

## Passo 2: Verificacao Final

- [ ] Testes passam
- [ ] TypeScript sem erros
- [ ] Build bem-sucedido
- [ ] Bug nao reproduz mais

---

## Passo 3: Memory Sync (se bug nao-obvio)

Se o bug foi dificil de encontrar, salvar na memory:

```javascript
mcp__memory__create_entities({
  entities: [{
    name: "{prefix}:bug:{nome-descritivo}",
    entityType: "bug",
    observations: [
      "Sintoma: [...]",
      "Causa raiz: [...]",
      "Solucao: [...]",
      "Arquivos: [...]"
    ]
  }]
})
```

---

## Passo 4: Checkpoint

```javascript
TodoWrite({
  todos: [
    { content: "Reproduce: bug reproduzido", status: "completed", activeForm: "Bug reproduced" },
    { content: "Investigate: causa raiz identificada", status: "completed", activeForm: "Root cause identified" },
    { content: "Fix: correcao implementada", status: "completed", activeForm: "Fix implemented" },
    { content: "Verify: quality gates passando", status: "completed", activeForm: "Quality gates passed" },
    { content: "Commit: commitar e push", status: "pending", activeForm: "Committing changes" }
  ]
})
```

---

## Output

Quality gates passando. Pronto para commit.

---

## Regras Inviolaveis

1. **PROIBIDO** prosseguir com testes falhando
2. **PROIBIDO** prosseguir com build falhando
3. **PROIBIDO** perguntar ao user (so reportar no final)

---
## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/debug/05-commit.md
