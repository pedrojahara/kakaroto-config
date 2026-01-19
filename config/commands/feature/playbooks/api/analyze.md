# API - Analyze

## Localizacao
- `api/handlers/` - Handler functions
- `api/routes/` - Route definitions
- `services/` - Business logic

## Pattern de Handler (Producao)
```typescript
export async function handleFeature(req, res) {
  const data = featureSchema.parse(req.body);
  const result = await featureService.execute(data);
  res.json(result);
}
```

## Criterios de Testabilidade
- Endpoint novo: Integration obrigatorio
- Validacao de input: Unit recomendado
- Multiplos servicos: Integration com mocks
