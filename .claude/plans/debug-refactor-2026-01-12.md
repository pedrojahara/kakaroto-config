# Plano: Refatorar /debug - Separar Reproduce de Investigate

## Tarefas

| # | Tarefa | Arquivos | Depende de |
|---|--------|----------|------------|
| 1 | Criar 01-reproduce.md | config/commands/debug/01-reproduce.md | - |
| 2 | Criar 02-investigate.md (extrair de 01-investigate) | config/commands/debug/02-investigate.md | 1 |
| 3 | Criar 03-fix.md (renumerar de 02-fix) | config/commands/debug/03-fix.md | 2 |
| 4 | Criar 04-verify.md (renumerar de 03-verify) | config/commands/debug/04-verify.md | 3 |
| 5 | Atualizar debug.md com novo fluxo | config/commands/debug.md | 4 |
| 6 | Deletar arquivos antigos | 01-investigate.md, 02-fix.md, 03-verify.md | 5 |
| 7 | Validar estrutura final | - | 6 |

## Analise Anti-Duplicacao

### Mapeamento de Codigo Reutilizavel

| Necessidade | Codigo Existente | Arquivo:Linha | Acao |
|-------------|------------------|---------------|------|
| Passos 1-3 de 01-reproduce | 01-investigate.md:1-58 | Passos 1-3 | Extrair |
| Passos 1-3 de 02-investigate | 01-investigate.md:59-120 | Passos 4-6 | Extrair |
| Conteudo de 03-fix | 02-fix.md:1-109 | Todo | Copiar + ajustar refs |
| Conteudo de 04-verify | 03-verify.md:1-67 | Todo | Copiar + ajustar refs |
| Pattern de gate | 02-fix.md:8-46 | Gate de Criticidade | Adaptar |
| Pattern de handoff | feature/02-spec.md:141-153 | Persistir Spec | Adaptar |
| Pattern de TodoWrite | feature/01-interview.md:121-137 | Checkpoint | Copiar |

### Checklist
- [x] Justifiquei cada arquivo NOVO? Sim (apenas 01-reproduce.md)
- [x] Verifiquei helpers similares existentes? Sim (patterns do /feature)
- [x] Codigo novo pode ser generalizado? N/A (templates .md)

## Resumo de Arquivos

**Criar:**
- config/commands/debug/01-reproduce.md (NOVO)
- config/commands/debug/02-investigate.md (REFATORADO)
- config/commands/debug/03-fix.md (RENUMERADO)
- config/commands/debug/04-verify.md (RENUMERADO)

**Modificar:**
- config/commands/debug.md (atualizar fluxo)

**Deletar:**
- config/commands/debug/01-investigate.md (substituido por 02-investigate)
- config/commands/debug/02-fix.md (substituido por 03-fix)
- config/commands/debug/03-verify.md (substituido por 04-verify)

## Implementacao Detalhada

### Tarefa 1: Criar 01-reproduce.md

Estrutura:
```markdown
# Fase 1: Reproduce

## Passo 1: Carregar Contexto
[Extrair de 01-investigate Passo 1]

## Passo 2: Reproduzir Bug
[Extrair de 01-investigate Passo 2]

## Passo 3: Verificar Estado Externo (CONDICIONAL)
[Extrair de 01-investigate Passo 3]

## Passo 4: Gate de Reproducao (NOVO)
SE reproduziu: continuar
SE NAO: AskUserQuestion

## Passo 5: Persistir Reproducao (NOVO)
Salvar em .claude/debug/reproduction.md

## Passo 6: Checkpoint (NOVO)
TodoWrite com status

## PROXIMA FASE
Read ~/.claude/commands/debug/02-investigate.md
```

### Tarefa 2: Criar 02-investigate.md

Estrutura:
```markdown
# Fase 2: Investigate

## Passo 0: Context (NOVO)
SE retomando: Read .claude/debug/reproduction.md

## Passo 1: Explorar Codigo Relacionado
[Extrair de 01-investigate Passo 4]

## Passo 2: 5 Whys (Causa Raiz)
[Extrair de 01-investigate Passo 5]

## Passo 3: Validar Causa Raiz
[Extrair de 01-investigate Passo 6]

## Passo 4: Checkpoint (NOVO)
TodoWrite com status

## PROXIMA FASE
Read ~/.claude/commands/debug/03-fix.md
```

### Tarefa 3-4: Renumerar fix e verify

- Mudar "Fase 2" para "Fase 3" no titulo de fix
- Mudar "Fase 3" para "Fase 4" no titulo de verify
- Ajustar referencias de "proxima fase"

### Tarefa 5: Atualizar debug.md

```markdown
## Fluxo
Reproduce → Investigate → Fix → Verify → Fim (SEM PARADAS)
```

## Riscos

| Risco | Probabilidade | Mitigacao |
|-------|---------------|-----------|
| Referencias quebradas | Media | Criar novos antes de deletar antigos |
| Conteudo perdido | Baixa | Validar linha a linha apos extracao |
| Handoff mal definido | Baixa | Usar pattern exato do /feature |

## Quality Gates

Apos implementacao:
- [ ] 4 arquivos de fase existem (01-reproduce, 02-investigate, 03-fix, 04-verify)
- [ ] Arquivos antigos deletados (01-investigate, 02-fix, 03-verify)
- [ ] Todas as referencias "PROXIMA FASE" corretas
- [ ] debug.md com fluxo de 4 fases
- [ ] Pattern de handoff implementado (.claude/debug/)
- [ ] TodoWrite checkpoints em todas as fases

## Validacao Final

```bash
# Estrutura de arquivos
ls config/commands/debug/
# Esperado: 01-reproduce.md, 02-investigate.md, 03-fix.md, 04-verify.md

# Referencias cruzadas
grep "02-investigate" config/commands/debug/01-reproduce.md
grep "03-fix" config/commands/debug/02-investigate.md
grep "04-verify" config/commands/debug/03-fix.md
```
