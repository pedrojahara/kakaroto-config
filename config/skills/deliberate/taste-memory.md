# Taste Memory — `.taste.json` spec

**Uso:** enviesar Move 2 scenario generation por preferências reveladas em deliberações anteriores **no mesmo projeto**. Advisory, não binding — anti-convergence rule domina.

## Localização

`.workflow/explorations/.taste.json` (project-relative). Ignorar em `.gitignore` é opcional — versionar pode ser útil para auditoria cross-team.

## Formato

```json
{
  "version": "1.0",
  "updated": "2026-04-20T14:30:00Z",
  "decisions": [
    {
      "topic": "auth",
      "slug": "authz-2026-04-10",
      "chosen": "Clerk híbrido com NextAuth session",
      "timestamp": "2026-04-10",
      "preferences_revealed": [
        "vendor-ok-se-compliance-aceitavel",
        "hibrido-preferido-sobre-puro",
        "evitar-self-host-quando-time-pequeno"
      ]
    },
    {
      "topic": "observability",
      "slug": "obs-2026-04-12",
      "chosen": "Grafana Cloud starter + OTel",
      "timestamp": "2026-04-12",
      "preferences_revealed": [
        "cost-sensitive-sobre-features",
        "open-standards-sobre-vendor-lock",
        "self-host-ok-se-baixo-ops"
      ]
    }
  ]
}
```

## Campos

- `version`: string. Atual `"1.0"`.
- `updated`: ISO-8601 timestamp da última modificação.
- `decisions[]`: array, mais recentes primeiro.
  - `topic`: área (auth, observability, cache, db, ux, etc.) — usado pra matching semântico.
  - `slug`: slug da deliberação para cross-reference.
  - `chosen`: cenário final refinado (não o nome do Move 2 cenário bruto).
  - `timestamp`: data da decisão.
  - `preferences_revealed[]`: kebab-case strings. Conjunto aberto mas prefira namespaces abaixo para consistência entre entries.

**Namespace sugerido** (use uma das categorias; evite inventar novas sem necessidade):

- **cost** — `cost-sensitive`, `cost-tolerant-if-time-critical`, `avoid-per-seat-pricing`
- **vendor** — `avoid-vendor-lock`, `vendor-ok-if-compliance-aceitavel`, `open-standards-over-proprietary`
- **ops** — `self-host-ok-small-team`, `prefer-managed-if-time-scarce`, `avoid-k8s-until-necessary`
- **arquitetura** — `monolito-first`, `microsservicos-only-when-scaling-diferencial`, `hibrido-preferido-sobre-puro`
- **scope** — `minimum-viable-first`, `prefer-reduction-over-expansion`, `expansion-if-leverage-obvio`
- **stack** — `typescript-strict`, `zod-for-external-input`, `evitar-orm-pesado`
- **ux** — `formulario-minimalista`, `progressive-disclosure`, `trust-before-data-collection`

Se a decisão não encaixa, criar namespace novo (1-word prefix + valor). Documentar a evolução na atualização de `.taste.json` comentando no topo do arquivo (se permitido pelo formato JSON — use campo `notes` a nível de decision).

## Como ler (no Move 2 Step 1)

1. `Read(.workflow/explorations/.taste.json)` — tolerar ausência.
2. Match semântico por `topic` e `preferences_revealed` com o problema atual.
3. Usar como **bias** nas narrativas dos 5 cenários:
   - "híbrido inteligente" que honra preferências reveladas ganha peso
   - se preferências revelam custo-sensitive, cenário "robusto/enterprise" deve explicitar custo alto
4. **Anti-convergence domina**: se taste force 4+ cenários convergentes, descartar bias — gerar spectrum genuíno mesmo que contradiga preferência histórica.

## Como escrever (no Output step, após save)

1. Ao salvar deliberação, extrair 2-4 `preferences_revealed` baseadas na decisão final vs rejected alternatives.
2. Merge em `.taste.json` (criar se não existir, append ao array `decisions`).
3. Atualizar campo `updated`.
4. Limit `decisions` a últimas 20 entries (truncar mais velhas).

## Guardrails

- **Taste é sinal, não regra.** Se o user contraria taste explícita no Move 2 choice, registrar nova preferência sem flag (preferências evoluem).
- **Conflitos** entre taste entries: preferir mais recente.
- **Cold start**: sem `.taste.json`, Move 2 gera spectrum puro sem bias — não forçar criação artificial.
- **Privacy**: arquivo não contém segredos; é seguro committar.
