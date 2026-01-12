# Fase 2: Investigate

## Passo 0: Context

**SE** continuacao direta de 01-reproduce (mesma sessao):
  Contexto ja disponivel, prosseguir.

**SE** retomando sessao interrompida:
```
Read .claude/debug/reproduction.md
```

---

## Passo 1: Explorar Codigo Relacionado

### 1.1 Buscar no Codebase
```
Grep: termos do bug
Glob: arquivos com nomes relacionados
git log --oneline --grep="fix" -- [arquivos suspeitos]
```

### 1.2 Identificar
- Arquivos/funcoes envolvidos
- Como erros sao tratados nesta area
- Ha validacao que deveria existir?
- Ha helper existente que resolve?

---

## Passo 2: 5 Whys (Causa Raiz)

Para cada "Por que?", fornecer EVIDENCIA de codigo:

```
ANALISE DE CAUSA RAIZ:

Sintoma: [o que esta acontecendo]

Por que #1: [resposta]
  Evidencia: [arquivo:linha] - [codigo]

Por que #2: [resposta]
  Evidencia: [arquivo:linha] - [codigo]

Por que #3: [resposta]
  Evidencia: [arquivo:linha] - [codigo]

CAUSA RAIZ: [declaracao clara]
```

---

## Passo 3: Validar Causa Raiz

A causa raiz deve ser:
- [ ] Algo que voce pode MUDAR
- [ ] Suportada por evidencia de codigo
- [ ] Explica TODOS os sintomas

**SE** nao validar: voltar ao Passo 2.

---

## Passo 4: Checkpoint

```javascript
TodoWrite({
  todos: [
    { content: "Reproduce: bug reproduzido", status: "completed", activeForm: "Bug reproduced" },
    { content: "Investigate: codigo explorado", status: "completed", activeForm: "Code explored" },
    { content: "Investigate: causa raiz identificada", status: "completed", activeForm: "Root cause identified" },
    { content: "Fix: implementar correcao", status: "pending", activeForm: "Implementing fix" }
  ]
})
```

---

## Output

Causa raiz documentada com evidencia.

---
## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/debug/03-fix.md
