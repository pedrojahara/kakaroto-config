# Cognitive Lenses — /deliberate

**Uso:** 18 lentes paralelas pra achar a premissa fragilest no Move 1 e orientar scenarios no Move 2. **Internalize — não enumere.** O output user-facing é UMA premissa identificada + evidência `path:line`, não um checklist. Cite o nome da lente no máximo uma ou duas vezes quando ela foi decisiva; nunca todas.

Aplicação em cada Move indicada em [Apply].

---

## 1. Classification instinct (Bezos)

Categorize decisões por reversibilidade × magnitude — one-way doors vs two-way doors. Escolhas irreversíveis merecem deliberação lenta; reversíveis, experimentação rápida.
[Apply: Move 1 classifica o caminho; Move 3 pre-mortem fica mais rigoroso para one-way doors]

## 2. Paranoid scanning (Grove)

Escaneie continuamente por inflection points, drift cultural, erosão de talento ou de pressupostos técnicos. O que está silenciosamente mudando enquanto o problema é debatido?
[Apply: Move 1 como lente de Step 0.5 audit — "o que mudou no git log -30 que contextualiza esse problema?"]

## 3. Inversion reflex (Munger)

Para cada "como vencemos?" pergunte "o que faria falhar?". Evita otimismo cego; expõe failure modes.
[Apply: Move 1 Thought 2 (FRAGILIDADE); Move 3 pre-mortem é inversão operacional]

## 4. Focus as subtraction (Jobs)

Valor vem do que NÃO fazer. Jobs cortou 350 produtos para 10. Toda decisão é também uma decisão do que deprecar/cortar.
[Apply: Move 2 cenário "mais simples possível"; Move 3 refinement — "o que cortar pra fortalecer?"]

## 5. People-first sequencing (Horowitz)

People, products, profits — sempre nessa ordem. Antes de escolher arquitetura, pergunte: o time tem capacidade / skill / apetite pra essa abordagem?
[Apply: Move 1 pergunta "quem vai manter isso em 6 meses?"; Move 2 calibra scenarios por team fit]

## 6. Speed calibration (Bezos)

Rápido é default. Lento só quando irreversível + alto impacto (combina com #1).
[Apply: Move 1 calibra urgência e intensidade do challenge — wartime demanda menos processo]

## 7. Proxy skepticism (Bezos Day 1)

Métricas continuam servindo usuários ou viraram auto-referenciais? Objetivos declarados são reais ou políticos?
[Apply: Move 1 desafia métricas citadas pelo user — "essa métrica reflete a dor ou virou objetivo por si só?"]

## 8. Narrative coherence

Decisões difíceis exigem framing claro; o "por quê" precisa ser legível pra um novo time chegando. Se você não consegue explicar a decisão em 2 parágrafos, não entendeu ainda.
[Apply: Move 3 Step 2 — quando refinement aceita concern, reescreva o "por quê" inteiro, não só patch]

## 9. Temporal depth

Pense em arcos de 5-10 anos; aplique regret minimization para decisões grandes. "Em 5 anos, vou me arrepender mais de ter feito isso ou de não ter feito?"
[Apply: já é spine do /deliberate via Dia 1 → Mês 6; em Move 1 pergunte "e em 2 anos?" pra complementar]

## 10. Founder-mode bias (Chesky/Graham)

Envolvimento profundo expande (não constrange) o pensamento do time. Delegação cega empobrece. Aplicada aqui: não terceirize a decisão pra "melhores práticas" sem entender o contexto.
[Apply: Move 1 resiste à resposta genérica — exige contexto específico do projeto]

## 11. Wartime awareness (Horowitz)

Peacetime vs wartime precisam diagnóstico antes de resposta. Soluções de peacetime em wartime matam a companhia; vice-versa abusa do time.
[Apply: Move 1 identifica postura — incidentes em produção, parceiros reclamando, receita em risco = wartime; exploratory greenfield = peacetime]

## 12. Courage accumulation

Confiança VEM de decisões difíceis tomadas; não precede. Espera não gera dados.
[Apply: Move 3 gate final — se user trava em "ainda não tenho dados pra decidir", pergunte: quando teria? O que muda o cálculo?]

## 13. Willfulness as strategy (Altman)

Empurre forte em uma direção por tempo suficiente. A maioria desiste cedo; persistência sobre a tese correta vira moat.
[Apply: Move 2 cenário "criativo/não-óbvio" frequentemente tem shape de "abordagem que ninguém mais faz mas compensa em 1 ano"]

## 14. Leverage obsession (Altman)

Procure inputs onde pouco esforço = output massivo. Tecnologia é leverage final.
[Apply: Move 2 cenário "criativo" — "qual abordagem dá 80% do valor com 20% do custo?"; Move 1 pergunta onde o leverage real está]

## 15. Hierarchy as service

Cada decisão de interface: o que o user vê primeiro, segundo, terceiro? Hierarquia comunica prioridade.
[Apply: decisões UX/frontend no Move 2; também APIs (qual campo vem primeiro na resposta comunica importance)]

## 16. Edge case paranoia

Nome = 47 chars? Zero resultados? Network falha mid-action? Double-click? Back button? Stale state?
[Apply: Move 3 Step 1 pre-mortem — quando listar failure modes, cover edges sistematicamente]

## 17. Subtraction default (Rams)

"As little design as possible." Corte elementos que não ganham pixels / linhas / espaço.
[Apply: Move 2 cenário "simples"; Move 3 refinement resiste inflar scope]

## 18. Design for trust

Cada decisão de interface constrói ou erode confiança. Pedir dados antes do valor gerar = erode. Loading spinner errado = erode. Erro críptico = erode.
[Apply: decisões UX/onboarding no Move 2 — cenários rankeados também por trust-posture]

---

## Meta-regra: ativação contextual

Nem toda lente se aplica a toda deliberação. Dado um problema:

- **Tech architecture** (SQL/NoSQL, monolito/micro): lentes 1, 3, 4, 6, 7, 11, 14 dominam
- **UX / onboarding** (drop-offs, flows): lentes 4, 8, 15, 16, 17, 18 dominam
- **Org / scaling** (team capacity, hiring): lentes 2, 5, 10, 11, 12 dominam
- **Cost / ops**: lentes 1, 6, 7, 14, 16 dominam
- **Deprecação / sunset**: lentes 1, 3, 4, 9 dominam

Use isso como map inicial. Se o problema híbrido, combine os grupos.
