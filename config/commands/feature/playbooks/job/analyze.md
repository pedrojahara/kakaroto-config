# Job - Analyze

## Localizacao
- `cron/` - Cron job definitions
- `jobs/` - Job handlers
- `executors/` - Job executors

## Pattern de Job (Producao)
```typescript
export async function executeFeatureJob(context: JobContext) {
  const items = await fetchPendingItems();
  for (const item of items) {
    await processItem(item);
  }
  return { processed: items.length };
}

// Executor pattern
export const featureExecutor = {
  name: 'feature-job',
  schedule: '0 */6 * * *',
  handler: executeFeatureJob
};
```

## Criterios de Testabilidade
- Job novo: Integration obrigatorio
- Logica de retry: Unit recomendado
- Job simples: Integration basico
