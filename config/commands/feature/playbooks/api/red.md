# API - RED (Testes)

## Testes Requeridos

| Tipo | Obrigatorio | Motivo |
|------|-------------|--------|
| Unit | SE complexo | Logica isolada com transformacoes |
| Integration | **SIM** | Fluxo completo request->response |
| E2E | NAO | API testada via integration |

## Mocks Tipicos
- Database: `vi.mock('./databaseService')`
- APIs externas (identificar do projeto)
- Auth/Session

## Test Pattern (Vitest)

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock antes do import
vi.mock('./databaseService', () => ({
  getAllItems: vi.fn(),
  createItem: vi.fn(),
  updateItem: vi.fn(),
}));

import { handleFeature } from './featureHandler';
import { getAllItems, createItem } from './databaseService';

describe('handleFeature', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return data when valid input', async () => {
    vi.mocked(getAllItems).mockResolvedValue([{ id: '1', name: 'Test' }]);

    const result = await handleFeature({ campaign: 'X' });

    expect(result.success).toBe(true);
    expect(getAllItems).toHaveBeenCalledTimes(1);
  });

  it('should handle empty results', async () => {
    vi.mocked(getAllItems).mockResolvedValue([]);

    const result = await handleFeature({ campaign: 'Y' });

    expect(result.success).toBe(true);
    expect(result.data).toEqual([]);
  });

  it('should propagate errors', async () => {
    vi.mocked(getAllItems).mockRejectedValue(new Error('DB error'));

    await expect(handleFeature({ campaign: 'Z' }))
      .rejects.toThrow('DB error');
  });
});
```

## Convenções
- 1 criterio do contract -> 1+ testes
- Usar `vi.mocked()` para type-safe mocks
- `beforeEach` com `vi.clearAllMocks()`
