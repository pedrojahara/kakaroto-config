# Claude Code Configuration Architecture

## Hierarquia de Arquivos

```
~/.claude/
├── CLAUDE.md / ARCHITECTURE.md
├── commands/           (invocados via /skill)
│   └── gate.md
├── skills/             (invocados via /skill, context fork)
│   ├── build/SKILL.md  (orquestrador)
│   ├── build-understand/SKILL.md
│   ├── build-verify/SKILL.md
│   ├── build-implement/SKILL.md
│   ├── certify/SKILL.md
│   ├── resolve/SKILL.md  (orquestrador)
│   ├── resolve-investigate/SKILL.md
│   ├── resolve-fix/SKILL.md
│   └── deliberate/SKILL.md
├── hooks/              (agent stop hooks)
│   └── build-implement-stop.sh
├── agents/             (invocados via Task tool)
│   ├── code-reviewer, test-fixer, code-simplifier
│   ├── functional-validator, terraform-validator
│   ├── build-implementer, resolve-fixer, memory-sync
│   └── (8 agents total)
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
| Certify | `certify/SKILL.md` | Quality agents -> deploy -> re-verify contra producao |

Accepts description or `.md` plan file path (auto-detected).
Routing: CLAUDE.md detecta trigger "criar/adicionar/implementar" -> `/build`

### /resolve (Bug Resolution)

| Fase | Arquivo | Acao |
|------|---------|------|
| Investigate | `resolve-investigate/SKILL.md` | ST hipoteses, prod logs, QA reproduction flows |
| Fix | `resolve-fix/SKILL.md` | Fix minimo + local QA verification via `resolve-fixer` agent |
| Certify | `certify/SKILL.md` | Quality agents -> deploy -> prod QA verification |

Pipeline: `INVESTIGATING -> DIAGNOSED -> FIXING -> CERTIFYING -> VERIFIED_PROD`
Trivial escape hatch: bugs >95% confidence fix+verify in Phase 1 (investigate).
Circuit breaker: Attempt 4 in fix -> re-investigate (max 1 cycle).

Routing: CLAUDE.md detecta trigger "bug/erro/problema" -> `/resolve`

### /gate (Quality Gate)

Ordem: `test-fixer (baseline)` -> `code-simplifier` -> `test-fixer (verificacao)` -> `code-reviewer` -> `functional-validator (se UI)` -> `terraform-validator (se env)`

---

## Agent Registry

| Agent | Modelo | Blocking | Proposito |
|-------|--------|----------|-----------|
| code-reviewer | opus | BLOCKING | Seguranca, tipagem, bugs |
| test-fixer | opus | BLOCKING | Rodar/corrigir/criar testes |
| code-simplifier | opus | non-blocking | Clareza, DRY, padroes |
| functional-validator | opus | BLOCKING | Playwright smoke tests em UI |
| terraform-validator | opus | BLOCKING | Consistencia env vars / .tf |
| build-implementer | opus | BLOCKING | Implementacao autonoma ate testes passarem |
| resolve-fixer | opus | BLOCKING | Fix autonomo de bugs ate QA flows passarem |
| memory-sync | opus | non-blocking | Sincroniza MCP Memory pos-workflow |

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

Regras: `STATUS=FAIL + BLOCKING=true` -> workflow PARA. `BLOCKING=false` -> continua com warning.

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
/deliberate # Design de solucao (adversarial, opcional)
/build      # Desenvolver feature completa (4-phase)
/resolve    # Resolver bug (3-phase: investigate -> fix -> certify)
/gate       # Quality gate pre-PR

# Skills locais (projeto/.claude/commands/)
# /deploy, /ship, etc.

# Agents (via Task tool)
# code-reviewer, test-fixer, code-simplifier,
# functional-validator, terraform-validator,
# build-implementer, resolve-fixer, memory-sync
```
