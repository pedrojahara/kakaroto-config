# Spec: [Nome da Feature]

## Metadata
- **Data:** [YYYY-MM-DD]
- **Interview:** `.claude/interviews/[slug].md`
- **Acceptance Criteria Source:** Interview Fase 1

---

## Resumo

[1-2 frases descrevendo o que a feature faz]

---

## Componentes

| Componente | Tipo | Descrição |
|------------|------|-----------|
| [nome] | Service/Handler/Component | [descrição] |

---

## Código a Reutilizar

| Necessidade | Código Existente | Ação |
|-------------|------------------|------|
| [o que precisa] | [arquivo:linha] ou "Não existe" | Reutilizar/Estender/Criar |

---

## Test Cases

### Acceptance Tests (OBRIGATÓRIOS)

| Acceptance Criterion (user) | Acceptance Test | Tipo |
|-----------------------------|-----------------|------|
| "[criterion 1 - linguagem do user]" | `it('[comportamento observável]')` | Integration/E2E |
| "[criterion 2 - linguagem do user]" | `it('[comportamento observável]')` | Integration/E2E |

**Validação mental:** Se este teste passar, o user validaria manualmente e ficaria satisfeito? ✓

### Unit Tests (se lógica complexa)

| Função | Test Case | Input → Output |
|--------|-----------|----------------|
| `[função]` | `[caso]` | `[input]` → `[output]` |

### Integration Tests (se multi-serviço)

| Fluxo | Serviços Envolvidos | Mock Strategy |
|-------|---------------------|---------------|
| `[fluxo]` | `[serviços]` | `[o que mockar]` |

### E2E Tests (se UI)

| Fluxo | Steps | Verificação |
|-------|-------|-------------|
| `[fluxo]` | `[passos]` | `[assertion]` |

---

## Mock Strategy

| Test Case | Mock Level | Serviços Mockados |
|-----------|------------|-------------------|
| [acceptance test 1] | integration | [apenas externos obrigatórios] |
| [unit test 1] | unit | - |

### Princípio de Mocks

- **Acceptance Tests:** Mínimo de mocks (apenas serviços externos obrigatórios)
- **Unit Tests:** Liberado para isolar

---

## Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `[path]` | Criar/Modificar | `[descrição]` |

---

## Dependências

- [ ] Nenhuma nova dependência
- [ ] Nova dependência: `[nome]` - Motivo: [explicação]

---

## Riscos Identificados

| Risco | Mitigação |
|-------|-----------|
| [risco] | [como mitigar] |

---

## Checklist de Spec

- [ ] Todos Acceptance Criteria têm Acceptance Test correspondente
- [ ] Acceptance Tests validam comportamento observável (não implementação)
- [ ] Mocks para Acceptance Tests são mínimos
- [ ] Código existente foi mapeado para reutilização
- [ ] Arquivos a criar/modificar estão listados
