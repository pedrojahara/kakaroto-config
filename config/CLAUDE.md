# Claude Code - Regras Globais

## Autonomia

FAZER, não perguntar. BUSCAR, não pedir contexto.

## Roteamento por Intenção

| Intenção                    | Comando                | Notas                              |
| --------------------------- | ---------------------- | ---------------------------------- |
| Implementar feature         | `/build <descrição>`   | Entrevista → spec → implementação  |
| Plano aprovado → executar   | Plan Mode → `/build`   | Ver regra abaixo                   |
| Pensar antes de implementar | `/deliberate`          | Zero código. Saída alimenta /build |
| Corrigir bug                | `/resolve <descrição>` | Investiga → diagnostica → corrige  |
| Revisar código alterado     | `/simplify`            | Reuso, qualidade, eficiência       |
| Deploy + verificação prod   | `/ship`                | Projeto-específico                 |

### Plan Mode → /build

Após ExitPlanMode aprovado, NÃO executar código diretamente:

1. Salvar plano em `.workflow/plans/{slug}.md` (slug: kebab-case do tópico)
2. Invocar `Skill("build", args: ".workflow/plans/{slug}.md")`

build-understand detecta PLAN MODE (arquivo `.md`) e pula entrevista/confirmação.

### REDIRECT

Se Agent retornar "REDIRECT": seguir a instrução — invocar o Skill indicado.

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
