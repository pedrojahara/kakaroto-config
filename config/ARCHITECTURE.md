# Claude Code Configuration Architecture

## Hierarquia de Arquivos

```
~/.claude/
├── CLAUDE.md / ARCHITECTURE.md
├── commands/           (invocados via /command)
│   └── gate.md
├── skills/             (invocados via /skill, context fork)
│   ├── build/SKILL.md                  (orquestrador - 4 fases)
│   ├── build-understand/SKILL.md       (+ spec-template.md; PLAN MODE + V4+ approval)
│   ├── build-implement/SKILL.md        (+ verify-template.md; effort xhigh)
│   ├── build-certify/SKILL.md          (quality agents + deploy + prod verification)
│   ├── resolve/SKILL.md                (orquestrador)
│   ├── resolve-investigate/SKILL.md    (+ diagnosis-template.md; REDIRECT -> /build)
│   ├── resolve-verify/SKILL.md         (user reviews diagnosis + QA flows)
│   ├── resolve-fix/SKILL.md
│   ├── resolve-certify/SKILL.md        (deploy + prod QA verification)
│   └── deliberate/SKILL.md             (+ output-template.md, standalone-template.md)
├── hooks/
│   ├── _lib.sh                         (helpers compartilhados)
│   ├── build-stop-guard.sh             (Stop: bloqueia stop durante workflow ativo)
│   ├── build-continuity-hook.sh        (PostToolUse Skill: injeta próximo Skill)
│   ├── build-skill-register.sh         (PreToolUse Skill: claims session ownership)
│   ├── build-session-recovery.sh       (SessionStart: detecta workflow stalled)
│   ├── build-implement-stop.sh         (Stop agent: enforce verify.sh --full)
│   ├── ask-user-empty-guard.sh         (PostToolUse AskUser: rejeita resposta vazia)
│   ├── pre-commit-gate.sh              (PreToolUse Bash: format + type-check + tests)
│   ├── stop-quality-check.sh           (Stop: quality gate antes de parar sessão)
│   ├── permission-denied-log.sh        (PermissionDenied: registra bloqueios de permissão)
│   └── pre-compact-save.sh             (PreCompact: preserva estado antes de compactação)
├── agents/             (invocados via Task tool, 8 total)
│   ├── code-reviewer, code-simplifier, test-fixer
│   ├── functional-validator, terraform-validator
│   └── build-implementer, resolve-fixer, memory-sync
└── settings.json       (hooks config, permissions)
```

Projetos adicionam `projeto/.claude/commands/` para skills locais (ex: `/deploy`, `/ship`).

---

## Workflows

### /build (Feature Development)

| Fase       | Arquivo                     | Ação                                                                                |
| ---------- | --------------------------- | ----------------------------------------------------------------------------------- |
| Understand | `build-understand/SKILL.md` | Interview + PLAN MODE detection + spec.md + V4+ approval gate                       |
| Implement  | `build-implement/SKILL.md`  | Anti-anchoring, exemplar study, codebase invariant check, `build-implementer` agent |
| Certify    | `build-certify/SKILL.md`    | Quality agents (reviewer-first em COMPLEX) → commit → deploy → prod V4+             |

Lifecycle: `DRAFTING → UNDERSTOOD → BUILDING → CERTIFYING → DONE`
(VERIFIED retido apenas para specs legacy; pipeline atual termina Understand em UNDERSTOOD após V4+ approval inline.)

Accepts description ou `.md` plan file path (auto-detectado por build-understand). Plan files pulam entrevista e gate de confirmação — o plano É o intent aprovado.

Quality tiers em build-certify:

- **TRIVIAL**: verify.sh baseline; invoca `code-reviewer` só se diff toca padrões de segurança.
- **STANDARD**: `code-reviewer` (correção + AC gaps).
- **COMPLEX**: `code-reviewer` primeiro (security/bugs/AC), depois `code-simplifier` (clareza/DRY sobre código corrigido).

Routing: CLAUDE.md detecta trigger "criar/adicionar/implementar" → `/build`

### /resolve (Bug Resolution)

| Fase        | Arquivo                        | Ação                                                                                                  |
| ----------- | ------------------------------ | ----------------------------------------------------------------------------------------------------- |
| Investigate | `resolve-investigate/SKILL.md` | Signal-driven triage + hipóteses + QA reproduction flows + REDIRECT → `/build` se for feature request |
| Verify      | `resolve-verify/SKILL.md`      | User reviews diagnosis + QA flows; gera verify.sh                                                     |
| Fix         | `resolve-fix/SKILL.md`         | Fix mínimo + local QA via `resolve-fixer` agent                                                       |
| Certify     | `resolve-certify/SKILL.md`     | Quality agents (simplifier-first em COMPLEX) → deploy → prod QA                                       |

Pipeline: `INVESTIGATING → DIAGNOSED → VERIFIED → FIXING → CERTIFYING → VERIFIED_PROD` (ou `FAILED`).
Trivial escape hatch: bugs >95% confiança fix+verify direto em investigate (skip fases seguintes).
Circuit breaker: Attempt 4 em fix → re-investigate (máx 1 ciclo).

Quality tiers em resolve-certify:

- **TRIVIAL**: skip quality agents; verify.sh + regression test da Phase B.2 são suficientes.
- **STANDARD**: `code-reviewer` only (foco no root cause fix).
- **COMPLEX**: `code-simplifier` primeiro, depois `code-reviewer` (ordem intencionalmente inversa a build-certify).

Routing: CLAUDE.md detecta trigger "bug/erro/problema" → `/resolve`. Se description soar feature → REDIRECT.

### /deliberate (Solution Design — Opcional)

`deliberate/SKILL.md`: 3 Moves adversariais (Frame challenge → Spectrum → Pre-mortem refinement). Zero código de produção; output alimenta `/build` com `.workflow/explorations/{slug}-deliberation.md`.

### /gate (Quality Gate manual)

Ordem: `test-fixer (baseline) → code-simplifier (DRY) → test-fixer (verificação) → code-reviewer → functional-validator (se UI) → terraform-validator (se env)`.

---

## Agent Registry

| Agent                | Modelo | Blocking     | Propósito                                                                        |
| -------------------- | ------ | ------------ | -------------------------------------------------------------------------------- |
| code-reviewer        | opus   | BLOCKING     | Segurança, tipagem, bugs, AC gaps (diff-only scope; confidence-based auto-fix)   |
| code-simplifier      | opus   | non-blocking | Clareza, DRY (rule-of-3 + knowledge-vs-char), padrões (NÃO-TOCAR error handling) |
| test-fixer           | opus   | BLOCKING     | Rodar/corrigir/criar testes                                                      |
| functional-validator | opus   | BLOCKING     | Playwright smoke tests em UI (auto-trigger em _.tsx/_.css)                       |
| terraform-validator  | opus   | BLOCKING     | Consistência env vars / .tf                                                      |
| build-implementer    | opus   | BLOCKING     | Implementação autônoma até verify.sh passar                                      |
| resolve-fixer        | opus   | BLOCKING     | Fix autônomo de bugs até QA flows passarem                                       |
| memory-sync          | opus   | non-blocking | Sincroniza MCP Memory pós-workflow                                               |

---

## Agent Output Format

Todos os agents retornam bloco padronizado (**última saída**; nada depois):

```
---AGENT_RESULT---
STATUS: PASS | FAIL
ISSUES_FOUND: <número>
ISSUES_FIXED: <número>
BLOCKING: true | false
---END_RESULT---
```

Regras: `STATUS=FAIL + BLOCKING=true` → workflow PARA. `BLOCKING=false` → continua com warning. `ISSUES_FIXED` só incrementa quando tsc+tests verificaram o fix (fail-safe).

---

## Triggers Automáticos

| Condição                          | Ação                            |
| --------------------------------- | ------------------------------- | ---------- | ---- | --- | ----- | ------ | ---- | ----- | ------ | -------- | ---- | ---- | -------------------------------- | ----------------------------------------- |
| Mudança em `*.tsx`, `*.css`       | `functional-validator` invocado |
| Mudança em `.env` ou `terraform/` | `terraform-validator` invocado  |
| Código novo sem teste             | `test-fixer` cria teste         |
| Fim de workflow                   | `memory-sync` atualiza Memory   |
| Diff toca `auth                   | session                         | permission | role | sql | query | crypto | sign | token | secret | sanitize | exec | eval | child_process` em TRIVIAL /build | `code-reviewer` invocado mesmo em TRIVIAL |

---

## Hooks Pipeline

| Hook                        | Event                         | Função                                                      |
| --------------------------- | ----------------------------- | ----------------------------------------------------------- |
| `build-skill-register.sh`   | PreToolUse (Skill)            | Claims session ownership para build/resolve sub-skills      |
| `build-continuity-hook.sh`  | PostToolUse (Skill)           | Injeta próximo Skill() call; previne narração entre fases   |
| `build-stop-guard.sh`       | Stop                          | Bloqueia stop enquanto workflow ativo; lê next-action.md    |
| `build-implement-stop.sh`   | Stop (agent)                  | Enforce verify.sh --full para build-implementer             |
| `build-session-recovery.sh` | SessionStart                  | Detecta workflows stalled (30min heartbeat), oferece resume |
| `ask-user-empty-guard.sh`   | PostToolUse (AskUserQuestion) | Rejeita resposta vazia/whitespace (empty-response guard)    |
| `pre-commit-gate.sh`        | PreToolUse (Bash)             | Auto-format + type-check + tests antes de git commit        |
| `stop-quality-check.sh`     | Stop                          | Bloqueia stop se mudanças não verificadas                   |
| `permission-denied-log.sh`  | PermissionDenied              | Registra bloqueios para revisão posterior                   |
| `pre-compact-save.sh`       | PreCompact                    | Preserva estado de workflow antes da compactação automática |

---

## Project Configuration

Certify skills descobrem deploy e auth config a partir do `CLAUDE.md` do projeto:

```markdown
## Deploy

### Commands

- Backend: `bash scripts/deploy.sh`
- Verify: `bash scripts/verify.sh`

### Production Auth

- API: `X-API-Key` header com API_KEY do .env
- Browser: use `e2eLogin()` helper

### Production Logs

- `bash scripts/logs.sh`
```

Discovery chain: Project CLAUDE.md `## Deploy` → MCP Memory → skip gracefully.
Sem `## Deploy`, certify roda quality agents + commit mas pula deploy e prod verification.

---

## Quick Reference

```bash
# Skills globais
/deliberate   # Design de solução (adversarial, opcional, zero código)
/build        # Feature (3-fase: understand → implement → certify; aceita plano .md)
/resolve      # Bug (4-fase: investigate → verify → fix → certify; REDIRECT se feature)
/gate         # Quality gate manual pré-PR

# Agents (via Task tool)
# code-reviewer, code-simplifier, test-fixer,
# functional-validator, terraform-validator,
# build-implementer, resolve-fixer, memory-sync
```
