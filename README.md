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

## What Gets Installed

```
.claude/
├── CLAUDE.md              # Global rules (autonomy, coding standards)
├── ARCHITECTURE.md        # Full documentation of the system
├── commands/              # Skills (invoked via /skill)
│   ├── feature.md         # /feature orchestrator
│   ├── feature/           # 5 phases: interview → spec → plan → implement → quality
│   ├── debug.md           # /debug orchestrator
│   ├── debug/             # 5 phases: reproduce → investigate → fix → verify → commit
│   └── gate.md            # /gate - quality gate before PR
└── agents/                # 7 specialized subagents
    ├── test-fixer.md
    ├── code-reviewer.md
    ├── code-simplifier.md
    ├── dry-enforcer.md
    ├── visual-validator.md
    ├── terraform-validator.md
    └── memory-sync.md
```

## Skills (Commands)

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/feature` | "adicionar", "implementar", "criar" | Full feature workflow with spec, planning, and quality gates |
| `/debug` | "bug", "erro", "problema" | Bug resolution with 5 Whys methodology |
| `/gate` | Manual | Run all 7 quality agents before PR |

## Agents (Subagents)

| Agent | Purpose |
|-------|---------|
| `test-fixer` | Runs tests, fixes failures, creates missing tests |
| `code-reviewer` | Reviews code quality, security, auto-fixes issues |
| `code-simplifier` | Reduces complexity, improves readability |
| `dry-enforcer` | Detects duplication, suggests code reuse |
| `visual-validator` | Validates UI with Playwright |
| `terraform-validator` | Validates env vars and Terraform consistency |
| `memory-sync` | Syncs knowledge to MCP Memory |

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

### Feature Development

```
User: "adiciona filtro de data na listagem"
         ↓
Claude automatically triggers /feature
         ↓
01-interview → Explores codebase, asks clarifying questions
02-spec      → Generates technical specification
03-planner   → Creates implementation plan (requires approval)
04-implement → Writes code following spec and plan
05-quality   → Runs all 7 quality agents
         ↓
Ready for PR
```

### Bug Resolution

```
User: "erro ao salvar formulario"
         ↓
Claude automatically triggers /debug
         ↓
01-reproduce   → Reproduces the bug
02-investigate → 5 Whys analysis with evidence
03-fix         → Minimal fix + mandatory test
04-verify      → Confirms fix works
05-commit      → Creates commit
         ↓
Done
```

## Requirements

- Claude Code CLI
- MCP Memory server (optional, for knowledge persistence)
- Playwright MCP (optional, for visual validation)

## License

MIT
