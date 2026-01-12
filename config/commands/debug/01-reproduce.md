# Fase 1: Reproduce

## Passo 1: Carregar Contexto

```
mcp__memory__search_nodes({ query: "config" })
mcp__memory__search_nodes({ query: "<termos-do-bug>" })
```

Extrair termos relevantes de $ARGUMENTS e buscar bugs similares ja resolvidos.

---

## Passo 2: Reproduzir Bug

### 2.1 Executar Passos
Tentar reproduzir com informacoes fornecidas.

### 2.2 Documentar
```
REPRODUCAO:
- Passos: [...]
- Input: [...]
- Output esperado: [...]
- Output real: [...]
- Reproduzido: SIM/NAO
```

---

## Passo 3: Verificar Estado Externo (SE web/scraping)

**APENAS SE** o bug envolve: web scraping, Playwright, Puppeteer, seletores, ou interacao com paginas web externas.

### 3.1 Verificar Antes de Assumir

```
1. mcp__playwright__browser_navigate({ url: "[URL do bug]" })
2. mcp__playwright__browser_wait_for({ time: 3 })
3. mcp__playwright__browser_snapshot({})
```

### 3.2 Comparar Estado Atual vs Esperado

- O que o codigo espera encontrar?
- O que realmente existe na pagina?
- Quais seletores existem/mudaram?

**PROIBIDO:** Assumir que "a pagina mudou" sem verificar.

---

## Passo 4: Gate de Reproducao

**SE** reproduziu com sucesso:
- Prosseguir para Passo 5

**SE NAO** reproduziu:
- Usar `AskUserQuestion` para obter mais detalhes
- Documentar o que foi tentado
- NAO prosseguir ate reproduzir

---

## Passo 5: Persistir Reproducao

Salvar documentacao em `.claude/debug/reproduction.md`:

```markdown
# Reproducao: [descricao curta do bug]

**Data:** [timestamp]
**Bug:** [descricao original de $ARGUMENTS]

## Passos de Reproducao
1. [passo executado]
2. [passo executado]

## Input
[dados de entrada usados]

## Output Esperado
[o que deveria acontecer]

## Output Real
[o que aconteceu - evidencia do bug]

## Observacoes Iniciais
[hipoteses formadas durante reproducao]

## Estado Externo (se aplicavel)
[observacoes do Playwright/browser]
```

---

## Passo 6: Checkpoint

```javascript
TodoWrite({
  todos: [
    { content: "Reproduce: contexto carregado", status: "completed", activeForm: "Loading context" },
    { content: "Reproduce: bug reproduzido", status: "completed", activeForm: "Reproducing bug" },
    { content: "Reproduce: reproducao persistida", status: "completed", activeForm: "Persisting reproduction" },
    { content: "Investigate: analisar causa raiz", status: "pending", activeForm: "Analyzing root cause" }
  ]
})
```

---

## Output

Bug reproduzido e documentado em `.claude/debug/reproduction.md`.

---
## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/debug/02-investigate.md
