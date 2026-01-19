# Job - E2E

## Tipo Recomendado: hybrid

Jobs requerem trigger manual ou aguardar schedule.

## Template

```markdown
## E2E Validation

**Tipo:** hybrid

**Acao do User:**
- [ ] Disparar job via admin/script
  OU
- [ ] Aguardar execucao automatica

**Verificacoes do Claude:**
- [ ] Query DB: verificar status do job
- [ ] Verificar logs: `grep "job.completed"`
- [ ] Confirmar side effects: registros processados > 0

**Criterio de Sucesso:**
- [ ] Job status = 'completed'
- [ ] Nenhum erro nos logs
```

## Alternativa: semi-auto
SE job puder ser disparado via API interna.
