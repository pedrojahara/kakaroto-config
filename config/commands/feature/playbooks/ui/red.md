# UI - RED (Testes)

## Testes Requeridos

| Tipo | Obrigatorio | Motivo |
|------|-------------|--------|
| Unit | SE hooks | Logica de hooks isolada |
| Integration | Opcional | Componentes complexos |
| E2E | **SIM** | Fluxo visual do usuario |

## Mocks Tipicos
- API routes: MSW ou fetch mock
- Context providers
- Next.js router

## Test Pattern - Hook (Vitest)

```typescript
import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useFeature } from './useFeature';

describe('useFeature', () => {
  it('should initialize with default state', () => {
    const { result } = renderHook(() => useFeature());
    expect(result.current.state).toEqual({ items: [], loading: false });
  });

  it('should update state on action', () => {
    const { result } = renderHook(() => useFeature());

    act(() => {
      result.current.actions.addItem({ id: '1', name: 'Test' });
    });

    expect(result.current.state.items).toHaveLength(1);
  });
});
```

## Test Pattern - Component (React Testing Library)

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { FeatureComponent } from './FeatureComponent';

describe('FeatureComponent', () => {
  it('should render items', () => {
    render(<FeatureComponent items={[{ id: '1', name: 'Test' }]} />);
    expect(screen.getByText('Test')).toBeInTheDocument();
  });

  it('should call onSubmit when form submitted', async () => {
    const onSubmit = vi.fn();
    render(<FeatureComponent onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText('Name'), {
      target: { value: 'New Item' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Submit' }));

    expect(onSubmit).toHaveBeenCalledWith({ name: 'New Item' });
  });
});
```

## Convenções
- Hooks: testar com `renderHook`
- Components: preferir queries por role/label
- Forms: testar submit e validacao
