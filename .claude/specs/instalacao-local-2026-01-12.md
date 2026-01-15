# Spec: Instalação Local por Padrão

**Status:** Draft

## Problema
Ao executar `npx kakaroto-config`, os arquivos são instalados globalmente em `~/.claude/`. Usuários querem a opção de instalar localmente na pasta do projeto.

## Solução
Mudar comportamento padrão para instalação local (`./.claude/`), mantendo opção de instalação global via flag `--global`.

## Escopo

### Inclui
- Instalação local por padrão em `./.claude/`
- Flag `--global` para instalação em `~/.claude/`
- Mensagens ajustadas conforme modo de instalação

### Não Inclui
- Outras flags ou opções
- Mudanças na estrutura dos arquivos de config
- Combinação local+global simultânea

## Design Técnico

### Dados
Nenhuma estrutura de dados nova.

### Services
| Service | Mudanças |
|---------|----------|
| bin/install.js | Adicionar detecção de `--global`, ajustar `CLAUDE_DIR` |

### Reutilização Obrigatória
| Existente | Uso |
|-----------|-----|
| `copyRecursive()` | Sem mudanças, reutilizar 100% |
| `countFiles()` | Sem mudanças, reutilizar 100% |
| `question()` | Sem mudanças, reutilizar 100% |

### Justificativa para Código Novo
| Novo Código | Por que não reutilizar existente? |
|-------------|-----------------------------------|
| Detecção de `--global` flag | Não existe lógica de args parsing |
| Variável `isGlobal` | Nova funcionalidade |

## Edge Cases
| Caso | Tratamento |
|------|------------|
| `./.claude/` já existe | Perguntar se quer sobrescrever (mesmo comportamento atual) |
| `--global` com `~/.claude/` existente | Perguntar se quer sobrescrever |
| Rodar de diretório sem permissão de escrita | Erro será mostrado pelo fs.mkdirSync |

## Testes

### Manuais
- [ ] `npx kakaroto-config` instala em `./.claude/`
- [ ] `npx kakaroto-config --global` instala em `~/.claude/`
- [ ] Mensagens refletem destino correto

## Decisões
| Decisão | Justificativa |
|---------|---------------|
| `process.argv.includes()` nativo | Projeto minimal, não adicionar deps |
| Local como padrão | Solicitado pelo user |
| Flag `--global` (não `-g`) | Mais explícito e claro |
