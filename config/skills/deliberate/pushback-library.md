# Pushback Library — Move 1 Step 4

**Uso:** 8 padrões BAD/GOOD de como desafiar premissas. Apply no Move 1 Step 4 antes de chamar AskUserQuestion. **Internalize o shape, não recite os exemplos.**

---

## Padrões gerais (adaptados de gstack office-hours)

### Pattern 1 — Vague scale claim → force specificity

- **BAD:** "Então vocês precisam escalar — quais servicos priorizar?"
- **GOOD:** "Nesse volume de 200 req/s (`apps/api/src/health.ts:15` log), nenhum dos 5 cenários que vou propor muda em resposta a carga. Escala não é o problema — o que degradou de fato?"

### Pattern 2 — Social proof → demand a test

- **BAD:** "Legal, mais alguém do time também prefere esse approach?"
- **GOOD:** "Gostar da ideia é grátis. Tem PR, RFC ou spike code? Alguém alocou tempo formal? Se não, pode ser entusiasmo passageiro — o que concretamente avançou essa decisão na semana passada?"

### Pattern 3 — Platform vision → wedge challenge

- **BAD:** "Como seria uma versão mínima dessa plataforma interna?"
- **GOOD:** "Se ninguém consegue tirar valor de uma versão menor, geralmente a proposta de valor ainda não está clara. Qual é o único use-case que justifica ship esta semana, sem os outros?"

### Pattern 4 — Industry stat → context test

- **BAD:** "Mercado de AI dev tools cresceu 300% — dá pra surfar essa onda."
- **GOOD:** "Crescimento de mercado não é vision. Todos os concorrentes citam a mesma stat. O que muda se o mercado encolher 50%? A decisão ainda faz sentido?"

### Pattern 5 — Undefined term → precision demand

- **BAD:** "Como vocês querem que o onboarding fique mais fluido?"
- **GOOD:** "'Fluido' não é feature. Especificamente qual passo causa drop-off? PostHog mostra 45% abandono no step 4 (`apps/web/src/pages/onboarding/step4.tsx:22`) — o problema é esse passo, não o flow inteiro."

---

## Padrões tech-originais (carry-over do audit)

### Pattern 6 — Take position, don't hedge

- **BAD:** "Talvez real-time não seja necessário?"
- **GOOD:** "Real-time não é necessário aqui: o scheduler `apps/bi-sync/cron.ts:12` roda a cada 30min e os analistas olham 2x/dia. Só discordo se houver consumidor com latência <1s."

### Pattern 7 — Specificity > vague concern

- **BAD:** "Você tem certeza que precisa microsserviço?"
- **GOOD:** "Extrair billing libera deploy independente, mas seu CI leva 8min (`.github/workflows/ci.yml:34`) — esse é o gargalo, não o acoplamento. Qual teu deploy frequency hoje?"

### Pattern 8 — Don't ask obvious questions

- **BAD:** "Você já pensou na escalabilidade?"
- **GOOD:** "A 200 req/s, nenhum dos 5 cenários que vou propor muda em resposta a carga. O bottleneck é em outro lugar — onde tá degradando de verdade?"

---

## Shape comum

Todos compartilham:

- Cita evidência concreta (`path:line`, número, log, commit)
- Toma posição — não abre um waffle de "depende"
- Abre UMA opção de escape pro user corrigir ("Só discordo se…", "a menos que…")
- Produz uma pergunta acionável no fim (não retórica)
