# Job - RED (Testes)

## Testes Requeridos

| Tipo | Obrigatorio | Motivo |
|------|-------------|--------|
| Unit | SE complexo | Logica de transformacao |
| Integration | **SIM** | Fluxo completo do job |
| E2E | NAO | Jobs testados via integration |

## Mocks Tipicos
- Database: `vi.mock('./databaseService')`
- Schedulers (Cloud Scheduler, cron)
- APIs externas (notificacoes, etc)
- Message queue (se aplicavel)

## Test Pattern (Vitest)

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('./databaseService', () => ({
  getPendingItems: vi.fn(),
  updateItemStatus: vi.fn(),
}));

import { executeFeatureJob } from './featureJob';
import { getPendingItems, updateItemStatus } from './databaseService';

describe('executeFeatureJob', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should process all pending items', async () => {
    vi.mocked(getPendingItems).mockResolvedValue([
      { id: '1', status: 'pending' },
      { id: '2', status: 'pending' },
    ]);
    vi.mocked(updateItemStatus).mockResolvedValue(undefined);

    const result = await executeFeatureJob({ runId: 'test' });

    expect(result.processed).toBe(2);
    expect(updateItemStatus).toHaveBeenCalledTimes(2);
  });

  it('should handle empty queue', async () => {
    vi.mocked(getPendingItems).mockResolvedValue([]);

    const result = await executeFeatureJob({ runId: 'test' });

    expect(result.processed).toBe(0);
    expect(updateItemStatus).not.toHaveBeenCalled();
  });

  it('should continue on item failure', async () => {
    vi.mocked(getPendingItems).mockResolvedValue([
      { id: '1', status: 'pending' },
      { id: '2', status: 'pending' },
    ]);
    vi.mocked(updateItemStatus)
      .mockRejectedValueOnce(new Error('Item 1 failed'))
      .mockResolvedValueOnce(undefined);

    const result = await executeFeatureJob({ runId: 'test' });

    expect(result.processed).toBe(1);
    expect(result.errors.length).toBe(1);
  });
});
```

## Convenções
- Testar processamento em batch
- Testar comportamento com erros parciais
- Testar fila vazia
