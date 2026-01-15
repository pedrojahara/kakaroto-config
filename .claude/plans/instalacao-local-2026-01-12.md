# Plano: Instalação Local por Padrão

## Tarefas

| # | Tarefa | Arquivos | Depende de |
|---|--------|----------|------------|
| 1 | Adicionar flag `--global` e lógica de detecção | bin/install.js | - |
| 2 | Mudar CLAUDE_DIR para local por padrão | bin/install.js | 1 |
| 3 | Atualizar mensagens de output | bin/install.js | 2 |
| 4 | Testar manualmente ambos cenários | - | 3 |

## Análise Anti-Duplicação

| Necessidade | Código Existente | Arquivo:Linha | Ação |
|-------------|------------------|---------------|------|
| Cópia recursiva | `copyRecursive()` | bin/install.js:22 | Reutilizar |
| Contagem de arquivos | `countFiles()` | bin/install.js:40 | Reutilizar |
| Prompt interativo | `question()` | bin/install.js:16 | Reutilizar |

## Resumo de Arquivos

**Modificar:**
- `bin/install.js` - adicionar flag e ajustar mensagens

**Criar:** Nenhum

**Deletar:** Nenhum

## Implementação Detalhada

### Tarefa 1-2: Flag e CLAUDE_DIR

```javascript
// Linha 8-9: Substituir
const isGlobal = process.argv.includes('--global');
const CLAUDE_DIR = isGlobal
  ? path.join(os.homedir(), '.claude')
  : path.join(process.cwd(), '.claude');
```

### Tarefa 3: Mensagens

- Linha 56-60: Mudar `~/.claude/` para mensagem dinâmica
- Linha 66: Ajustar pergunta de overwrite
- Linha 72-74: Ajustar confirmação de instalação

## Quality Gates

- [ ] Script executa sem erros
- [ ] Instalação local funciona
- [ ] Instalação global com `--global` funciona
