# Claude Code - Regras Globais

## Autonomia
FAZER, não perguntar. BUSCAR, não pedir contexto.

## Workflows

| Comando | Escopo | Trigger |
|---------|--------|---------|
| `/build` | Global | criar/adicionar/implementar feature |
| `/resolve` | Global | bug/erro/problema |
| `/ship` | **Local** | E2E + Deploy (projeto-específico) |

## Código
- Funções < 50 linhas, max 2 níveis nesting
- TypeScript strict, ES modules, async/await
- Zod para inputs externos
- PROIBIDO: `any`, try/catch genérico, callbacks

## Testes (BLOQUEANTE)
Código sem teste = PR rejeitado.
Exceções: config files, .d.ts, UI puro sem lógica.

## Memory
Namespace: ver CLAUDE.md do projeto.
Sincronizar via `memory-sync` ao final de workflows.
