# Claude Code Configuration Architecture

## Hierarquia de Arquivos

```
~/.claude/
├── CLAUDE.md / ARCHITECTURE.md
├── commands/           (invocados via /command)
│   └── gate.md
├── skills/             (invocados via /skill, context fork)
│   ├── build/SKILL.md            (orquestrador)
│   ├── build-understand/SKILL.md (+ spec-template.md)
│   ├── build-verify/SKILL.md     (+ verify-template.md)
│   ├── build-implement/SKILL.md
│   ├── build-certify/SKILL.md    (quality + deploy + prod verification)
│   ├── resolve/SKILL.md          (orquestrador)
│   ├── resolve-investigate/SKILL.md (+ diagnosis-template.md)
│   ├── resolve-verify/SKILL.md   (user reviews diagnosis + QA flows)
│   ├── resolve-fix/SKILL.md
│   ├── resolve-certify/SKILL.md  (deploy + prod QA verification)
│   └── deliberate/SKILL.md       (+ output-template.md, standalone-template.md)
├── hooks/
│   ├── build-stop-guard.sh       (Stop: prevents stop during active workflow)
│   ├── build-continuity-hook.sh  (PostToolUse Skill: injects next action)
│   ├── build-skill-register.sh   (PreToolUse Skill: claims session ownership)
│   ├── build-session-recovery.sh (SessionStart: detects stalled workflows)
│   ├── build-implement-stop.sh   (Stop: enforces verify.sh --full for agents)
│   └── ask-user-empty-guard.sh   (PostToolUse AskUserQuestion: rejects empty)
├── agents/             (invocados via Task tool, 8 total)
│   ├── code-reviewer, test-fixer, code-simplifier
│   ├── functional-validator, terraform-validator
│   └── build-implementer, resolve-fixer, memory-sync
└── settings.json       (hooks config, permissions)
```

Projetos adicionam `projeto/.claude/commands/` para skills locais (ex: `/deploy`, `/ship`).

---

## Workflows

### /build (Feature Development)

| Fase          | Arquivo                     | Acao                                                      |
| ------------- | --------------------------- | --------------------------------------------------------- |
| Understand    | `build-understand/SKILL.md` | Product surface, interview, understand requirements       |
| Verify Design | `build-verify/SKILL.md`     | Design QA-style V4+ verification scripts                  |
| Implement     | `build-implement/SKILL.md`  | Anti-anchoring, exemplar study, `build-implementer` agent |
| Certify       | `build-certify/SKILL.md`    | Quality agents -> deploy -> prod V4+ verification         |

Lifecycle: `DRAFTING -> UNDERSTOOD -> VERIFIED -> BUILDING -> CERTIFYING -> DONE`

Accepts description or `.md` plan file path (auto-detected by build-understand).
Plan files skip the interview and confirmation gate — the plan IS the approved intent.

Routing: CLAUDE.md detecta trigger "criar/adicionar/implementar" -> `/build`

### /resolve (Bug Resolution)

| Fase        | Arquivo                        | Acao                                                         |
| ----------- | ------------------------------ | ------------------------------------------------------------ |
| Investigate | `resolve-investigate/SKILL.md` | ST hipoteses, prod logs, QA reproduction flows               |
| Verify      | `resolve-verify/SKILL.md`      | User reviews diagnosis + QA flows, generates verify.sh       |
| Fix         | `resolve-fix/SKILL.md`         | Fix minimo + local QA verification via `resolve-fixer` agent |
| Certify     | `resolve-certify/SKILL.md`     | Quality agents -> deploy -> prod QA verification             |

Pipeline: `INVESTIGATING -> DIAGNOSED -> VERIFIED -> FIXING -> CERTIFYING -> VERIFIED_PROD`
Trivial escape hatch: bugs >95% confidence fix+verify in Phase 1 (investigate), skips all remaining phases.
Circuit breaker: Attempt 4 in fix -> re-investigate (max 1 cycle).

Routing: CLAUDE.md detecta trigger "bug/erro/problema" -> `/resolve`

### /gate (Quality Gate)

Ordem: `test-fixer (baseline)` -> `code-simplifier` -> `test-fixer (verificacao)` -> `code-reviewer` -> `functional-validator (se UI)` -> `terraform-validator (se env)`

---

## Agent Registry

| Agent                | Modelo | Blocking     | Proposito                                  |
| -------------------- | ------ | ------------ | ------------------------------------------ |
| code-reviewer        | opus   | BLOCKING     | Seguranca, tipagem, bugs                   |
| test-fixer           | opus   | BLOCKING     | Rodar/corrigir/criar testes                |
| code-simplifier      | opus   | non-blocking | Clareza, DRY, padroes                      |
| functional-validator | opus   | BLOCKING     | Playwright smoke tests em UI               |
| terraform-validator  | opus   | BLOCKING     | Consistencia env vars / .tf                |
| build-implementer    | opus   | BLOCKING     | Implementacao autonoma ate testes passarem |
| resolve-fixer        | opus   | BLOCKING     | Fix autonomo de bugs ate QA flows passarem |
| memory-sync          | opus   | non-blocking | Sincroniza MCP Memory pos-workflow         |

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

| Condicao                          | Acao                            |
| --------------------------------- | ------------------------------- |
| Mudanca em `*.tsx`, `*.css`       | `functional-validator` invocado |
| Mudanca em `.env` ou `terraform/` | `terraform-validator` invocado  |
| Codigo novo sem teste             | `test-fixer` cria teste         |
| Fim de workflow                   | `memory-sync` atualiza Memory   |

---

## Hooks Pipeline

| Hook                        | Event                         | Funcao                                                       |
| --------------------------- | ----------------------------- | ------------------------------------------------------------ |
| `build-skill-register.sh`   | PreToolUse (Skill)            | Claims session ownership for build/resolve sub-skills        |
| `build-continuity-hook.sh`  | PostToolUse (Skill)           | Injects next Skill() call, prevents narration between phases |
| `build-stop-guard.sh`       | Stop                          | Blocks stop while workflow active; reads next-action.md      |
| `build-implement-stop.sh`   | Stop (agent)                  | Enforces verify.sh --full for build-implementer agent        |
| `build-session-recovery.sh` | SessionStart                  | Detects stalled workflows (30min heartbeat), offers resume   |
| `ask-user-empty-guard.sh`   | PostToolUse (AskUserQuestion) | Rejects empty/blank responses (accidental submissions)       |

---

## Project Configuration

Certify skills discover deploy and auth config from the project's CLAUDE.md:

```markdown
## Deploy

### Commands

- Backend: `bash scripts/deploy.sh`
- Verify: `bash scripts/verify.sh`

### Production Auth

- API: `X-API-Key` header with API_KEY from .env
- Browser: use `e2eLogin()` helper for browser tests

### Production Logs

- `bash scripts/logs.sh`
```

**Discovery chain:** Project CLAUDE.md `## Deploy` → Memory → skip gracefully.
Without `## Deploy`, certify runs quality agents + commit but skips deploy and prod verification.

---

## Quick Reference

```bash
# Skills globais
/deliberate # Design de solucao (adversarial, opcional)
/build      # Desenvolver feature (4-phase, accepts plan files)
/resolve    # Resolver bug (4-phase: investigate -> verify -> fix -> certify)
/gate       # Quality gate pre-PR

# Skills locais (projeto/.claude/commands/)
# /deploy, /ship, etc.

# Agents (via Task tool)
# code-reviewer, test-fixer, code-simplifier,
# functional-validator, terraform-validator,
# build-implementer, resolve-fixer, memory-sync
```
