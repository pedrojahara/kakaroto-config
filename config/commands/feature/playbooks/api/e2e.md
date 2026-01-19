# API - E2E

## Tipo Recomendado: semi-auto

API pode ser testada via request + verificacao automatizada.

## Template

```markdown
## E2E Validation

**Tipo:** semi-auto

**Trigger:** `POST /api/{endpoint}` com payload:
```json
{ "field": "value" }
```

**Verificacoes do Claude:**
- [ ] Response status 200/201
- [ ] Response body contem campos esperados
- [ ] Query DB: verificar registro criado/atualizado

**Criterio de Sucesso:**
- [ ] Record existe no DB com campos corretos
```

## Alternativa: hybrid
SE depender de integracao externa (OAuth, webhook externo).
