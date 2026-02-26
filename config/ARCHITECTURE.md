# Claude Code Configuration Architecture

## Hierarquia de Arquivos

```
~/.claude/
├── CLAUDE.md / ARCHITECTURE.md
├── commands/           (invocados via /skill)
│   ├── resolve.md + resolve/{01-understand,02-resolve}.md
│   └── gate.md
├── skills/             (invocados via /skill, context fork)
│   ├── build/SKILL.md  (orquestrador)
│   ├── build-understand/SKILL.md
│   ├── build-verify/SKILL.md
│   └── build-implement/SKILL.md
├── agents/             (invocados via Task tool)
│   ├── code-reviewer, test-fixer, code-simplifier
│   ├── functional-validator, terraform-validator
│   ├── build-implementer, memory-sync
│   └── (7 agents total)
└── *-defaults.json
```

Projetos adicionam `projeto/.claude/commands/` para skills locais (ex: `/deploy`, `/ship`).

---

## Workflows

### /build (Feature Development)

| Fase | Arquivo | Acao |
|------|---------|------|
| Understand | `build-understand/SKILL.md` | Product surface, interview, understand requirements |
| Verify Design | `build-verify/SKILL.md` | Design QA-style human-action verification scripts |
| Implement | `build-implement/SKILL.md` | Code exploration, anti-anchoring, `build-implementer` agent |
| Certify | (inline Phase 3) | Quality agents → deploy → re-verify contra producao |

Routing: CLAUDE.md detecta trigger "criar/adicionar/implementar" → `/build`

### /resolve (Bug Resolution)

| Fase | Arquivo | Acao |
|------|---------|------|
| Understand | `resolve/01-understand.md` | ST profundo + 5 Whys + hipoteses rankadas |
| Resolve | `resolve/02-resolve.md` | Fix minimo + self-healing (H1→H2→H3→PARAR) + commit |

Routing: CLAUDE.md detecta trigger "bug/erro/problema" → `/resolve`

### /gate (Quality Gate)

Ordem: `test-fixer (baseline)` → `code-simplifier` → `test-fixer (verificacao)` → `code-reviewer` → `functional-validator (se UI)` → `terraform-validator (se env)`

---

## Agent Registry

| Agent | Modelo | Blocking | Proposito |
|-------|--------|----------|-----------|
| code-reviewer | opus | BLOCKING | Seguranca, tipagem, bugs |
| test-fixer | sonnet | BLOCKING | Rodar/corrigir/criar testes |
| code-simplifier | sonnet | non-blocking | Clareza, DRY, padroes |
| functional-validator | sonnet | BLOCKING | Playwright smoke tests em UI |
| terraform-validator | sonnet | BLOCKING | Consistencia env vars / .tf |
| build-implementer | opus | BLOCKING | Implementacao autonoma ate testes passarem |
| memory-sync | haiku | non-blocking | Sincroniza MCP Memory pos-workflow |

---

## Agent Output Format

Todos os agents retornam bloco padronizado:

```
---AGENT_RESULT---
STATUS: PASS | FAIL
ISSUES_FOUND: <numero>
ISSUES_FIXED: <numero>
BLOCKING: true | false
---END_RESULT---
```

Regras: `STATUS=FAIL + BLOCKING=true` → workflow PARA. `BLOCKING=false` → continua com warning.

---

## Triggers Automaticos

| Condicao | Acao |
|----------|------|
| Mudanca em `*.tsx`, `*.css` | `functional-validator` invocado |
| Mudanca em `.env` ou `terraform/` | `terraform-validator` invocado |
| Codigo novo sem teste | `test-fixer` cria teste |
| Fim de workflow | `memory-sync` atualiza Memory |

---

## Quick Reference

```bash
# Skills globais
/build      # Desenvolver feature completa
/resolve    # Resolver bug (2-phase)
/gate       # Quality gate pre-PR

# Skills locais (projeto/.claude/commands/)
# /deploy, /ship, etc.

# Agents (via Task tool)
# code-reviewer, test-fixer, code-simplifier,
# functional-validator, terraform-validator,
# build-implementer, memory-sync
```
