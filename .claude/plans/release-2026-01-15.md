# Plano: Comando Release

## Analise Anti-Duplicacao

### Codigo Reutilizavel
| Necessidade | Codigo Existente | Arquivo:Linha | Acao |
|-------------|------------------|---------------|------|
| Estrutura script | bin/install.js | :1-124 | Seguir pattern |
| readline prompt | bin/install.js | :30-39 | Copiar pattern |
| Feedback visual | bin/install.js | :54-56 | Copiar pattern |

### Justificativa para Codigo Novo
- `bin/release.js`: Script com proposito diferente de install.js. Compartilhar codigo adicionaria acoplamento desnecessario.

## Breakdown de Tarefas

| # | Tarefa | Arquivos | Depende de |
|---|--------|----------|------------|
| 1 | Criar script release.js | bin/release.js | - |
| 2 | Adicionar npm script | package.json | 1 |
| 3 | Testar manualmente | - | 2 |

## Detalhamento da Tarefa 1

### bin/release.js - Estrutura

```
1. Imports (fs, path, os, readline, child_process)
2. Constants (HOME_CLAUDE, PROJECT_ROOT, CONFIG_DIR, EXCLUDED)
3. Helper functions:
   - question(prompt) - readline wrapper
   - cleanDir(dir) - rm -rf recursivo
   - copyRecursive(src, dest, excludes) - copia com filtro
   - bumpVersion(version) - incrementa patch
   - execCommand(cmd, desc) - execSync wrapper
4. main() - fluxo principal
```

### Fluxo do main()

```
1. Verificar ~/.claude existe
2. Ler package.json, calcular nova versao
3. Mostrar preview:
   - Arquivos a sincronizar
   - Versao atual → nova
4. Confirmar (Y/n)
5. Limpar config/commands/ e config/agents/
6. Copiar arquivos (exceto audit-command)
7. Atualizar package.json com nova versao
8. git add . && git commit && git push
9. npm publish
10. Mostrar sucesso
```

## Resumo de Arquivos

**Criar:**
- `bin/release.js`

**Modificar:**
- `package.json` (adicionar script "release")

## Riscos

| Risco | Probabilidade | Mitigacao |
|-------|---------------|-----------|
| npm nao autenticado | Baixa | Erro claro, user faz npm login |
| git push falha | Baixa | Erro claro, user faz push manual |

## Quality Gates

- [ ] Script executa sem erros de sintaxe
- [ ] Arquivos sao copiados corretamente
- [ ] Version bump funciona
- [ ] Git commit/push funciona
- [ ] npm publish funciona

## Decisoes Tomadas

| Decisao | Opcoes | Escolha | Justificativa |
|---------|--------|---------|---------------|
| Sem testes automatizados | Com/Sem | Sem | Script de release, validacao manual suficiente |
| Limpar dirs antes de copiar | Sim/Nao | Sim | Evita arquivos orfaos |
| Uma confirmacao | Multiplas/Uma | Uma | Simplicidade, git permite reverter |

## Decisoes Pendentes

Nenhuma - todas as decisoes foram tomadas na Interview.
