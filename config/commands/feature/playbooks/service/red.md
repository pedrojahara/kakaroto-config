# Service - RED (Testes)

## Testes Requeridos

| Tipo | Obrigatorio | Motivo |
|------|-------------|--------|
| Unit | **SIM** | Logica pura e isolada |
| Integration | SE multi-service | Interacao entre servicos |
| E2E | NAO | Servicos testados via unit/integration |

## Mocks Tipicos
- Database: `vi.mock('./databaseService')`
- APIs externas
- File system (se aplicavel)

## Test Pattern (Vitest) - Service

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('./databaseService', () => ({
  getAll: vi.fn(),
  getItems: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
}));

import { processItems } from './itemService';
import { getAll, create } from './databaseService';

describe('processItems', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should create new items from unique tags', async () => {
    vi.mocked(getAll).mockResolvedValue([
      { id: 'item-1', tags: ['Tag A'] },
      { id: 'item-2', tags: ['Tag A', 'Tag B'] },
    ]);
    vi.mocked(create).mockResolvedValue('new-id');

    const result = await processItems();

    expect(result.success).toBe(true);
    expect(result.created).toBe(2);
    expect(create).toHaveBeenCalledTimes(2);
  });
});
```

## Test Pattern (Vitest) - Utility

```typescript
import { describe, it, expect } from 'vitest';
import { transformData } from './dataTransformer';

describe('transformData', () => {
  it('should transform input correctly', () => {
    const input = { raw: 'value' };
    const result = transformData(input);
    expect(result.processed).toBe('VALUE');
  });

  it('should handle edge cases', () => {
    expect(transformData({ raw: '' })).toEqual({ processed: '' });
    expect(transformData({ raw: null })).toEqual({ processed: null });
  });
});
```

## Convenções
- Services: mock dependencias externas
- Utilities: testar como funcoes puras (sem mocks)
- `vi.clearAllMocks()` no beforeEach
