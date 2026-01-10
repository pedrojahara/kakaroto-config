# kakaroto-config

Claude Code configuration for autonomous development workflows.

## Quick Install

```bash
npx kakaroto-config
```

This installs the configuration to `~/.claude/`.

## What's Included

### Skills (Commands)

| Skill | Description |
|-------|-------------|
| `/feature` | Full feature development workflow (interview → spec → plan → implement → quality) |
| `/debug` | Bug resolution with 5 Whys methodology (investigate → fix → verify) |
| `/gate` | Quality gate before PR (runs 7 validation agents) |

### Agents (Subagents)

| Agent | Purpose |
|-------|---------|
| `test-fixer` | Runs tests, fixes failures, creates missing tests |
| `code-reviewer` | Reviews code quality, security, auto-fixes issues |
| `code-simplifier` | Reduces complexity, improves readability |
| `dry-enforcer` | Detects duplication, suggests reuse |
| `visual-validator` | Validates UI with Playwright |
| `terraform-validator` | Validates env vars and Terraform consistency |
| `memory-sync` | Syncs knowledge to MCP Memory |

## Philosophy

- **FAZER, não perguntar** - Agents fix issues automatically
- **BUSCAR, não pedir contexto** - Use MCP Memory and codebase exploration
- **Código sem teste = PR rejeitado** - Tests are mandatory
- **Erros: corrigir e continuar** - Don't stop on failures

## Documentation

After installation, read `~/.claude/ARCHITECTURE.md` for full documentation.

## License

MIT
