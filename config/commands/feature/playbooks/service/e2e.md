# Service - E2E

## Tipo Recomendado: auto (integration test)

Services sao testados via integration tests existentes.

## Template

```markdown
## E2E Validation

**Tipo:** auto

**Script/Ferramenta:** integration test existente

**Cenario:**
- Given: {pre-condicao}
- When: service.execute({input})
- Then: {resultado esperado}

**Comando:** `npm test -- --grep "{nome-do-teste}"`
```

## Alternativa: hybrid
SE depender de sistema externo nao mockavel.
