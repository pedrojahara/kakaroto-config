# UI - Analyze

## Localizacao
- `components/` - React components
- `app/` - Next.js pages/routes
- `hooks/` - Custom hooks

## Pattern de Component (Producao)
```typescript
export function FeatureComponent({ data }: FeatureProps) {
  const { state, actions } = useFeature(data);
  return <div>...</div>;
}

// Hook pattern
export function useFeature(initial) {
  const [state, setState] = useState(initial);
  // ...
  return { state, actions };
}
```

## Criterios de Testabilidade
- Formulario novo: E2E obrigatorio
- Hook com logica: Unit obrigatorio
- Componente display-only: Nenhum
