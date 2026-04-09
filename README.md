# kakaroto-config

Claude Code configuration for autonomous development workflows.

## Quick Install

```bash
# Local installation (recommended - installs to ./.claude/)
npx kakaroto-config

# Global installation (installs to ~/.claude/)
npx kakaroto-config --global
```

**Local is recommended** because each project can have its own customizations while inheriting the global rules.

## Updating

To update to the latest version, run the same command again:

```bash
# Update local installation
npx kakaroto-config@latest

# Update global installation
npx kakaroto-config@latest --global
```

The installer will detect the existing `.claude/` folder and ask if you want to overwrite.

> **Note:** If you previously installed globally (`~/.claude/`) and want to switch to local (`./.claude/`), just run `npx kakaroto-config@latest` in your project folder. Both can coexist - Claude Code will use local config when available.

## What Gets Installed

```
.claude/
├── CLAUDE.md              # Global rules (autonomy, coding standards)
├── ARCHITECTURE.md        # Full documentation of the system
├── skills/                # Skill workflows (invoked via /skill)
│   ├── build/SKILL.md         # /build orchestrator
│   ├── build-understand/      # Phase: requirements (handles plan files too)
│   ├── build-verify/          # Phase: QA verification design
│   ├── build-implement/       # Phase: autonomous implementation
│   ├── build-certify/         # Phase: quality + deploy + prod verification
│   ├── resolve/SKILL.md       # /resolve orchestrator
│   ├── resolve-investigate/   # Phase: diagnosis + QA reproduction
│   ├── resolve-verify/        # Phase: user reviews diagnosis + QA flows
│   ├── resolve-fix/           # Phase: autonomous fix + local QA
│   ├── resolve-certify/       # Phase: deploy + production QA
│   └── deliberate/            # /deliberate - adversarial solution design
├── commands/              # Commands (invoked via /command)
│   └── gate.md            # /gate - quality gate before PR
├── hooks/                 # Workflow lifecycle hooks
│   ├── build-stop-guard.sh       # Prevents stop during active workflow
│   ├── build-continuity-hook.sh  # Injects next action between phases
│   ├── build-skill-register.sh   # Claims session ownership
│   ├── build-session-recovery.sh # Detects and resumes stalled workflows
│   ├── build-implement-stop.sh   # Enforces verify.sh for agents
│   └── ask-user-empty-guard.sh   # Rejects empty AskUserQuestion responses
└── agents/                # 8 specialized agents
    ├── build-implementer.md
    ├── resolve-fixer.md
    ├── test-fixer.md
    ├── code-reviewer.md
    ├── code-simplifier.md
    ├── functional-validator.md
    ├── terraform-validator.md
    └── memory-sync.md
```

## Skills & Commands

| Name | Type | Trigger | Description |
|------|------|---------|-------------|
| `/deliberate` | Skill | Manual | Adversarial solution designer: challenges framing, simulates scenarios as temporal narratives |
| `/build` | Skill | "adicionar", "implementar", "criar" | Full feature workflow: understand -> verify -> implement -> certify. Accepts plan files (.md paths) |
| `/resolve` | Skill | "bug", "erro", "problema" | Bug resolution: investigate -> verify -> fix -> certify |
| `/gate` | Command | Manual | Run quality agents before PR |

### Workflow Chain

```
/deliberate (optional) Solution design: challenge framing, scenarios, refinement
   |
/build                 Implementation: spec -> verify -> code -> certify
```

```
/resolve               Autonomous bug fix: diagnose -> verify -> fix -> certify
```

## Agents (Subagents)

| Agent | Model | Blocking | Purpose |
|-------|-------|----------|---------|
| `build-implementer` | opus | yes | Autonomous implementation from spec, codes until tests pass |
| `resolve-fixer` | opus | yes | Autonomous bug fix, codes until QA flows pass |
| `code-reviewer` | opus | yes | Security, types, bugs |
| `test-fixer` | opus | yes | Runs tests, fixes failures, creates missing tests |
| `code-simplifier` | opus | no | Clarity, DRY, patterns |
| `functional-validator` | opus | yes | Validates UI with Playwright (auto-triggered on .tsx/.css changes) |
| `terraform-validator` | opus | yes | Validates env vars and Terraform consistency |
| `memory-sync` | opus | no | Syncs knowledge to MCP Memory |

## Philosophy

The configuration enforces autonomous development:

| Principle | Meaning |
|-----------|---------|
| **FAZER, nao perguntar** | Agents fix issues automatically, don't ask for confirmation |
| **BUSCAR, nao pedir contexto** | Use MCP Memory and codebase exploration, don't ask user for context |
| **Codigo sem teste = PR rejeitado** | Tests are mandatory (blocking) |
| **Erros: corrigir e continuar** | Fix errors automatically, don't stop workflow |

## After Installation

### 1. Create Project CLAUDE.md (Optional but Recommended)

Create a `CLAUDE.md` in your project root with project-specific info:

```markdown
# Project Name

## Commands
- `npm run dev` - Start dev server
- `npm run build` - Build
- `npm run test` - Run tests

## Structure
- `src/` - Source code
- `tests/` - Tests

## MCP Memory Namespace
Prefix: `myproject:`
```

### 2. Add Custom Skills (Optional)

Create `.claude/commands/your-skill.md` for project-specific workflows.

## Workflow Examples

### Solution Design (/deliberate)

```
User: "/deliberate como resolver o problema de cache"
         |
Claude triggers /deliberate
         |
Move 1: Challenge the frame (hidden assumptions)
Move 2: Simulate 5+ scenarios as temporal narratives (Dia 1 -> Mes 6)
Move 3: Pre-mortem + collaborative refinement
         |
Saves deliberation with /build command ready
```

### Feature Development (/build)

```
User: "adiciona filtro de data na listagem"
         |
Claude automatically triggers /build
         |
build-understand -> Aligns on WHAT to build (user approval gate)
build-verify     -> Designs QA-style human-action test scripts (user approval gate)
build-implement  -> Autonomous implementation until verify.sh passes
certify          -> Quality agents + deploy + production verification
         |
Done
```

### Bug Resolution (/resolve)

```
User: "erro ao salvar formulario"
         |
Claude automatically triggers /resolve
         |
resolve-investigate -> Diagnoses root cause + QA reproduction flows
resolve-verify      -> User reviews diagnosis + approves QA flows
resolve-fix         -> Autonomous fix + local QA verification
resolve-certify     -> Quality agents + deploy + production QA
         |
Done (trivial bugs skip directly from investigate)
```

## Customizing for Your Project

The certify skills automatically discover deploy and auth configuration from your project's `CLAUDE.md`. Add a `## Deploy` section to enable production verification:

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

Without this section, certify runs quality agents and commits but skips deploy and production verification.

## Requirements

- Claude Code CLI
- MCP Memory server (optional, for knowledge persistence)
- Playwright MCP (optional, for functional validation)
- Sequential Thinking MCP (optional, for /deliberate)
- Context7 MCP (optional, for library documentation)

## Development

### Releasing a New Version

This project uses `~/.claude/` as the source of truth. To publish changes:

```bash
npm run release
```

This command will:
1. Sync files from `~/.claude/` to `config/` (excluding personal files like `audit-command/`)
2. Bump the patch version automatically
3. Create a git commit and push
4. Publish to npm

**Files synced:**
- `CLAUDE.md`, `ARCHITECTURE.md`
- `skills/` (build, resolve, deliberate workflows)
- `commands/` (gate)
- `agents/` (all 8 subagents)
- `hooks/` (6 lifecycle hooks)
- `templates/` (if present)

**Files excluded:**
- `audit-command/` (personal)
- `build-plan/`, `think/` (personal)
- Session data (`plans/`, `specs/`, `interviews/`, etc.)

## License

MIT
