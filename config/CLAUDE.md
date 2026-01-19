# Claude Code - Regras Globais

## Autonomia
FAZER, não perguntar. BUSCAR, não pedir contexto.

## Workflows
| Trigger | Ação |
|---------|------|
| criar/adicionar/implementar feature | `/feature` |
| bug/erro/problema | `/debug` |

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

## Auto-Avaliacao
Apos /feature e /debug: executar fase de avaliacao (07/06-evaluate).
Dual-loop sequential thinking: diagnostico → sintese → propor melhorias ao user.

## Workflow Recovery

**Pós-compaction:** SE output do hook mostra `WORKFLOW RECOVERY REQUIRED`:

1. `Read .claude/workflow-state.json`
2. `Read ~/.claude/commands/feature/{currentPhase}.md`
3. `Read` artefatos não-null: interview, analysis, contract, spec, plan
4. Retomar de `lastStep` usando `resumeHint`

**AUTOMÁTICO** - não perguntar ao user, apenas retomar.
