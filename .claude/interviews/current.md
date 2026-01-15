# Interview: Comando Release

## Contexto Descoberto
- Scripts existentes: `bin/install.js` (instalador que copia config/ para destino)
- Pattern: npm scripts em package.json + bin/
- Arquivos fonte: `~/.claude/` (CLAUDE.md, ARCHITECTURE.md, commands/, agents/)
- Arquivos destino: `config/` no projeto

## Estrutura Atual
| Local | Arquivos |
|-------|----------|
| ~/.claude/commands/ | feature/, debug/, gate.md, audit-command/ |
| ~/.claude/agents/ | 7 subagents |
| config/commands/ | feature/ (5 fases), debug/ (5 fases), gate.md |
| config/agents/ | 7 subagents |

## Gap Identificado
- 25+ arquivos em ~/.claude/ que não estão em config/
- feature/ tem 07-evaluate.md no global mas não no projeto
- debug/ tem playbooks/, techniques/, templates/, validators/ no global

## Perguntas e Respostas
| # | Pergunta | Resposta | Impacto na Implementacao |
|---|----------|----------|--------------------------|
| 1 | Nome do comando | npm run release | Script em package.json |
| 2 | Bump de versao | Automatico (patch) | Incrementar patch no package.json |
| 3 | Incluir audit-command | Nao, pessoal | Excluir audit-command da copia |

## Decisoes Implicitas
- Git push: automatico (faz sentido para release)
- npm publish: automatico (proposito do comando)
- Exclusoes: plans/, specs/, interviews/, audit-command/

## Termos-chave para Busca
- release, sync, publish, config, package.json, bin/

## Escopo do Comando
1. Copiar ~/.claude/{CLAUDE.md, ARCHITECTURE.md} para config/
2. Copiar ~/.claude/commands/ para config/commands/ (excluindo audit-command/)
3. Copiar ~/.claude/agents/ para config/agents/
4. Bump patch version em package.json
5. Git add + commit + push
6. npm publish
