# Claude Code — Regras Globais

## Autonomia

FAZER, não perguntar. BUSCAR, não pedir contexto.

## Roteamento por Intenção

| Intenção                    | Comando                | Notas                                                            |
| --------------------------- | ---------------------- | ---------------------------------------------------------------- |
| Implementar feature         | `/build <descrição>`   | Entrevista → spec → implementação → certifica                    |
| Plano aprovado → executar   | Plan Mode → `/build`   | Ver regra abaixo                                                 |
| Pensar antes de implementar | `/deliberate`          | Zero código. Saída alimenta `/build`                             |
| Corrigir bug                | `/resolve <descrição>` | Investiga → diagnostica → verifica → corrige → certifica em prod |
| Revisar código alterado     | `/simplify` (bundled)  | Reuso, qualidade, eficiência                                     |

### Plan Mode → /build

Após ExitPlanMode aprovado, NÃO executar código diretamente:

1. Salvar plano em `.workflow/plans/{slug}.md` (slug: kebab-case do tópico)
2. Invocar `Skill("build", args: ".workflow/plans/{slug}.md")`

build-understand detecta PLAN MODE (arquivo `.md`) e pula entrevista/confirmação.

### Routing automático entre /resolve e /build

- `/resolve` detecta feature requests (ex: "quero um botão novo") e rotea para `/build` sozinho.
- Escolha o comando que melhor reflete sua intenção; o pipeline se auto-corrige.

## Configuração por Projeto

Cada projeto pode (e deve) ter seu próprio `CLAUDE.md` na raiz com:

**Obrigatório:**

- `## Stack` — linguagens e frameworks principais
- `## Commands` — test, dev, build (comandos que `/resolve` Phase B e `/build` consultam)
- `## Memory` — namespace único do projeto (prefixo em entidades de memória)

**Opcional (se aplicável):**

- `## Deploy` — comandos de deploy, auth de produção, query de logs (consumido por `resolve-certify` e `build-certify`)
- `## Resolve Patterns` — Test Commands, Test Dirs, Domain Signals, Bug Archetypes (consumido por `resolve-investigate` Phase A.3)
- `## Skills Específicas` — comandos custom do projeto em `.claude/commands/` (ex: `/ship` em social-medias)

Exemplos de referência: `social-medias/CLAUDE.md` (completo), `investing/CLAUDE.md` (minimalista).

## Código

- Funções < 50 linhas, max 2 níveis nesting
- TypeScript strict, ES modules, async/await
- Zod para inputs externos
- PROIBIDO: `any`, try/catch genérico, callbacks

## Testes (BLOQUEANTE)

Código sem teste = PR rejeitado.
Exceções: config files, `.d.ts`, UI puro sem lógica.

## Memory

Namespace: ver CLAUDE.md do projeto.
Sincronizar via `Task(memory-sync)` ao final de workflows.
