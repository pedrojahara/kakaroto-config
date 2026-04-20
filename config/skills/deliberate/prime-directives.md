# Prime Directives — checklist Move 3 pre-mortem

**Uso:** cross-check da mitigation proposta no Move 3 Step 1. Cite apenas as diretrizes que se aplicam; não force todas. Se uma diretriz é violada pelo cenário chosen, **é obrigatório** propor mitigation que resolva, ou aceitar explicitamente como Risk Accepted com justificativa.

---

1. **Zero silent failures.** Todo failure mode precisa ser visível pro sistema, time ou user. Nada falha sem sinal. Cheque: todo failure path identificado tem alerta, log, ou retorno estruturado?

2. **Every error has a name.** Exception class nomeada, trigger, handler, mensagem user-facing, test coverage. "Erro genérico" é dívida.

3. **Data flows have shadow paths.** Pra cada fluxo de dados, mapear paths: null, empty/zero-length, upstream-error. Foi pensado o que acontece quando chega vazio? Quando upstream falha?

4. **Interactions have edge cases.** Double-click, navegar-away no meio, conexão lenta, stale state, back button. Cheque: UI/interaction changes preveem esses?

5. **Observability is scope.** Novos dashboards, alertas, runbooks são deliverables first-class — não opcional. Se a decisão afeta prod, inclua observabilidade na mitigation.

6. **Diagrams are mandatory.** Gstack exige ASCII diagrams pra todo data flow, state machine, pipeline. Para `/deliberate` (pré-código), diagrams são **opcionais** — mas se a decisão é sobre arquitetura complexa, um ASCII diagram no pre-mortem vale muito.

7. **Everything deferred is written down.** TODOS.md ou não existe. Se a decisão adia trade-offs ("vamos refatorar depois"), escreva onde e quando o "depois" é.

8. **Optimize for 6-month future.** Resolva o hoje sem criar o pesadelo de próximo trimestre. Combina com temporal depth (Cognitive Lens #9).

9. **Permission to scrap.** "Scrap it and do this instead" se emerge abordagem fundamentalmente melhor no Move 3 refinement. Não se prenda ao Move 2 winner.

---

## Como aplicar

No Move 3 Step 1, depois de listar failure modes e propor mitigations, faça uma passada rápida pelos 9:

- Diretrizes violadas sem mitigation → forçar uma OR aceitar como `Risks Accepted` com justificativa.
- Diretrizes irrelevantes ao cenário → pular silenciosamente.
- Diretrizes satisfeitas → mencionar brevemente no output se load-bearing ("observability coberta via X").

Não transforme o output do Move 3 num form preenchido — usa como scan, não como template.
