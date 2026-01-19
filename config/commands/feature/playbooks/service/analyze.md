# Service - Analyze

## Localizacao
- `services/` - Business logic services
- `utils/` - Utility functions
- `lib/` - Shared libraries

## Pattern de Service (Producao)
```typescript
export const featureService = {
  async execute(input: FeatureInput): Promise<FeatureOutput> {
    const validated = featureSchema.parse(input);
    // business logic
    return result;
  }
};

// Utility pattern
export function transformData(input: Input): Output {
  // pure transformation
  return output;
}
```

## Criterios de Testabilidade
- Funcao pura: Unit obrigatorio
- Servico com DB: Unit + Integration
- Utility simples: Unit basico
