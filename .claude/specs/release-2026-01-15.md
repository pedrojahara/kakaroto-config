# Spec: Comando Release

## Resumo
Comando `npm run release` que sincroniza arquivos de configuracao de `~/.claude/` para o projeto, faz bump de versao, commit/push no git e publica no npm.

## Arquivos a Criar/Modificar

| Arquivo | Acao | Descricao |
|---------|------|-----------|
| `bin/release.js` | Criar | Script principal de release |
| `package.json` | Modificar | Adicionar script "release" |

## Especificacao Tecnica

### bin/release.js

```javascript
#!/usr/bin/env node

// Imports
const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');
const { execSync } = require('child_process');

// Constants
const HOME_CLAUDE = path.join(os.homedir(), '.claude');
const PROJECT_ROOT = path.join(__dirname, '..');
const CONFIG_DIR = path.join(PROJECT_ROOT, 'config');

// Exclusions (nao copiar esses arquivos/pastas)
const EXCLUDED_COMMANDS = ['audit-command', 'audit-command.md'];
```

### Fluxo de Execucao

1. **Mostrar preview**
   - Listar arquivos que serao copiados
   - Mostrar versao atual e nova versao (patch bump)

2. **Confirmar com user**
   - Prompt: "Proceed with release? (Y/n)"
   - Se 'n', abortar

3. **Sync arquivos**
   - Limpar `config/commands/` e `config/agents/` (rm -rf)
   - Copiar `~/.claude/CLAUDE.md` → `config/CLAUDE.md`
   - Copiar `~/.claude/ARCHITECTURE.md` → `config/ARCHITECTURE.md`
   - Copiar `~/.claude/commands/*` → `config/commands/` (exceto audit-command)
   - Copiar `~/.claude/agents/*` → `config/agents/`

4. **Bump version**
   - Ler `package.json`
   - Parse version (semver)
   - Incrementar patch: `1.0.1` → `1.0.2`
   - Salvar `package.json`

5. **Git operations**
   ```bash
   git add .
   git commit -m "release: v{version}"
   git push
   ```

6. **NPM publish**
   ```bash
   npm publish
   ```

7. **Output**
   - Mostrar sucesso
   - Mostrar nova versao publicada

### Funcoes

| Funcao | Descricao |
|--------|-----------|
| `copyRecursive(src, dest, excludes)` | Copia recursiva com filtro de exclusao |
| `cleanDir(dir)` | Remove diretorio recursivamente |
| `bumpVersion(version)` | Incrementa patch version |
| `execCommand(cmd, description)` | Executa comando shell com feedback |
| `question(prompt)` | Prompt interativo |
| `main()` | Fluxo principal |

### package.json (modificacao)

```json
{
  "scripts": {
    "release": "node bin/release.js"
  }
}
```

## Criterios de Aceite

- [ ] `npm run release` executa o script
- [ ] Arquivos sao copiados corretamente de ~/.claude/ para config/
- [ ] audit-command/ nao e copiado
- [ ] Version e incrementada (patch)
- [ ] Commit e criado com mensagem "release: vX.X.X"
- [ ] Push e feito para remote
- [ ] Pacote e publicado no npm
- [ ] User pode cancelar antes de executar

## Dependencias

Apenas Node.js built-ins:
- fs
- path
- os
- readline
- child_process

## Riscos e Mitigacoes

| Risco | Mitigacao |
|-------|-----------|
| npm publish falha | Mostrar erro claro, git ja commitado permite retry |
| git push falha | Mostrar erro, user pode fazer push manual |
| Arquivos orfaos em config/ | Limpar commands/ e agents/ antes de copiar |
