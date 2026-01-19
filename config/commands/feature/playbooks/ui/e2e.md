# UI - E2E

## Tipo Recomendado: auto (Playwright)

Fluxos visuais testados via browser automation.

## Template

```markdown
## E2E Validation

**Tipo:** auto

**Script/Ferramenta:** Playwright + functional-validator

**Cenario:**
- Given: Usuario na pagina {page}
- When: Usuario preenche form e submete
- Then: {resultado visual/funcional}

**Comando:** `npm run test:e2e -- {arquivo.spec.ts}`
```

## Playwright Pattern

```typescript
import { test, expect } from '@playwright/test';

test('should submit form successfully', async ({ page }) => {
  await page.goto('/feature');

  await page.fill('[name="title"]', 'Test Title');
  await page.fill('[name="description"]', 'Test Description');
  await page.click('button[type="submit"]');

  await expect(page.locator('.success-message')).toBeVisible();
  await expect(page).toHaveURL(/\/feature\/[a-z0-9]+/);
});
```

## Alternativa: hybrid (fallback)
SE Playwright falhar ou for overkill:

```markdown
## E2E Validation

**Tipo:** hybrid

**Acao do User:**
- [ ] Navegue para {url}
- [ ] Execute {acao}
- [ ] Confirme visualmente o resultado

**Verificacoes do Claude:**
- [ ] API call: `GET /api/{resource}` retorna dados esperados
- [ ] Query DB: verificar dados persistidos

**Criterio de Sucesso:**
- [ ] User confirma que UI funcionou
- [ ] Dados persistidos corretamente
```
