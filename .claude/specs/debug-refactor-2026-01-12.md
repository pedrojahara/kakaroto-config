# Spec: Refatorar /debug - Separar Reproduce de Investigate

**Status:** Draft

## Problema
O comando `/debug` fase `01-investigate.md` tem 6 responsabilidades misturadas (~120 linhas), dificultando que o Claude mantenha foco e siga gates corretamente. Falta alinhamento com patterns do `/feature` (handoffs, TodoWrite, persistência).

## Solucao
Separar `01-investigate.md` em duas fases distintas: `01-reproduce.md` (reproduzir bug) e `02-investigate.md` (encontrar causa raiz), com handoffs claros e persistência em `.claude/debug/`.

## Escopo

### Inclui
- Nova fase `01-reproduce.md` (~50 linhas)
- Refatorar `01-investigate.md` para `02-investigate.md` (~60 linhas)
- Renumerar `02-fix.md` para `03-fix.md`
- Renumerar `03-verify.md` para `04-verify.md`
- Atualizar `debug.md` com novo fluxo
- Handoff via `.claude/debug/reproduction.md`
- TodoWrite checkpoints em todas as fases

### Nao Inclui
- Mudancas no conteudo do fix ou verify (apenas renumeracao)
- Novos agentes ou ferramentas
- Mudancas no `/feature`

## Design Tecnico

### Estrutura de Arquivos

**ANTES:**
```
config/commands/debug/
├── 01-investigate.md (120 linhas, 6 responsabilidades)
├── 02-fix.md
└── 03-verify.md
```

**DEPOIS:**
```
config/commands/debug/
├── 01-reproduce.md (NOVO - ~50 linhas)
├── 02-investigate.md (REFATORADO - ~60 linhas)
├── 03-fix.md (RENUMERADO)
└── 04-verify.md (RENUMERADO)

.claude/debug/
└── reproduction.md (RUNTIME - handoff)
```

### Conteudo de Cada Fase

#### 01-reproduce.md (NOVO)

| Passo | Descricao | Origem |
|-------|-----------|--------|
| 1 | Carregar Contexto (memory search) | Atual Passo 1 |
| 2 | Reproduzir Bug (tentar + documentar) | Atual Passo 2 |
| 3 | Verificar Estado Externo (condicional web) | Atual Passo 3 |
| 4 | Gate: Reproduziu? | NOVO |
| 5 | Persistir em .claude/debug/reproduction.md | NOVO |
| 6 | Checkpoint TodoWrite | NOVO |

**Gate Explicito:**
```markdown
## Passo 4: Gate de Reproducao

**SE** reproduziu com sucesso:
- Prosseguir para Passo 5

**SE NAO** reproduziu:
- Usar AskUserQuestion para mais detalhes
- NAO prosseguir ate reproduzir
```

**Formato de Handoff (reproduction.md):**
```markdown
# Reproducao: [descricao curta]

**Data:** [timestamp]
**Bug:** [descricao original]

## Passos de Reproducao
1. [passo]
2. [passo]

## Input
[dados de entrada]

## Output Esperado
[o que deveria acontecer]

## Output Real
[o que aconteceu]

## Observacoes Iniciais
[hipoteses formadas durante reproducao]

## Estado Externo (se aplicavel)
[observacoes do Playwright]
```

#### 02-investigate.md (REFATORADO)

| Passo | Descricao | Origem |
|-------|-----------|--------|
| 0 | Context (ler reproduction.md se retomando) | NOVO |
| 1 | Explorar Codigo Relacionado | Atual Passo 4 |
| 2 | 5 Whys (Causa Raiz) | Atual Passo 5 |
| 3 | Validar Causa Raiz | Atual Passo 6 |
| 4 | Checkpoint TodoWrite | NOVO |

#### 03-fix.md e 04-verify.md

- Apenas renumeracao
- Ajustar referencias de "proxima fase"
- Conteudo mantem igual

### Reutilizacao Obrigatoria

| Existente | Uso |
|-----------|-----|
| Passo 1-3 do atual 01-investigate.md | Base para 01-reproduce.md |
| Passo 4-6 do atual 01-investigate.md | Base para 02-investigate.md |
| Pattern de gate do /feature | Aplicar em 01-reproduce.md |
| Pattern de handoff do /feature | Aplicar para .claude/debug/ |
| Pattern de TodoWrite do /feature | Adicionar em todas as fases |

### Justificativa para Conteudo Novo

| Novo | Por que nao reutilizar existente? |
|------|-----------------------------------|
| Gate de reproducao (Passo 4) | Nao existe gate explicito atual |
| Persistencia reproduction.md | /debug nao usa handoff via arquivo |
| TodoWrite checkpoints | /debug nao usa TodoWrite |

## Edge Cases

| Caso | Tratamento |
|------|------------|
| Sessao interrompida apos reproducao | 02-investigate le .claude/debug/reproduction.md |
| Bug trivial (obvio de onde vem) | Ainda passa por ambas fases, mas rapido |
| Bug de web/scraping | Condicional no Passo 3 de 01-reproduce |
| Nao consegue reproduzir | Gate bloqueia, AskUserQuestion |

## Testes

### Manuais
| Cenario | Verificacao |
|---------|-------------|
| Bug simples | Fluxo completo funciona |
| Bug de web | Passo 3 (Playwright) executa |
| Sessao interrompida | Retomada funciona via reproduction.md |
| Nao reproduz | Gate bloqueia e pergunta |

## Decisoes

| Decisao | Justificativa |
|---------|---------------|
| 2 fases (nao 3) | Balanco entre granularidade e overhead |
| Persistir apenas reproducao | Investigacao e consumida imediatamente pelo fix |
| Passo 3 inline (nao arquivo separado) | Nao justifica complexidade extra |
| TodoWrite em todas as fases | Alinhamento com /feature |
