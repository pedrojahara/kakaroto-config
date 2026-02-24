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
│   ├── build/SKILL.md     # /build - feature implementation
│   ├── build-understand/  # Phase: deep requirements gathering
│   └── build-implement/   # Phase: autonomous implementation
├── commands/              # Commands (invoked via /command)
│   ├── resolve.md         # /resolve orchestrator
│   ├── resolve/           # 2 phases: understand → resolve
│   └── gate.md            # /gate - quality gate before PR
└── agents/                # 7 specialized subagents
    ├── build-implementer.md
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
| `/build` | Skill | "adicionar", "implementar", "criar" | Full feature workflow: understand → implement → quality |
| `/resolve` | Command | "bug", "erro", "problema" | Bug resolution: understand → resolve |
| `/gate` | Command | Manual | Run quality agents before PR |

## Agents (Subagents)

| Agent | Purpose |
|-------|---------|
| `build-implementer` | Autonomous implementation from spec, codes until tests pass |
| `test-fixer` | Runs tests, fixes failures, creates missing tests |
| `code-reviewer` | Reviews code quality, security, auto-fixes issues |
| `code-simplifier` | Reduces complexity, improves readability |
| `functional-validator` | Validates UI with Playwright (auto-triggered on .tsx/.css changes) |
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

### Feature Development (/build)

```
User: "adiciona filtro de data na listagem"
         ↓
Claude automatically triggers /build
         ↓
build-understand → Deep requirements gathering, hypothesis diversification
build-implement  → Autonomous implementation until tests pass
quality          → Runs quality agents
         ↓
Ready for PR
```

### Bug Resolution (/resolve)

```
User: "erro ao salvar formulario"
         ↓
Claude automatically triggers /resolve
         ↓
01-understand → Reproduces and investigates the bug
02-resolve    → Fixes with minimal change + mandatory test
         ↓
Done
```

## Requirements

- Claude Code CLI
- MCP Memory server (optional, for knowledge persistence)
- Playwright MCP (optional, for functional validation)

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
- `skills/` (build workflows)
- `commands/` (resolve, gate)
- `agents/` (all subagents)
- `templates/` (if present)

**Files excluded:**
- `audit-command/` (personal)
- Session data (`plans/`, `specs/`, `interviews/`, etc.)

## License

MIT
