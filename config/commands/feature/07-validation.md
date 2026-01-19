# Fase 7: Validation

## Responsabilidade
E2E Validation - verificar que feature funciona no mundo real.

---

## Passo 1: Pre-flight Check (BLOCKING)

```bash
# Ler contract path do state
CONTRACT=$(jq -r '.contract' .claude/workflow-state.json)

# Verificar que contract existe e tem E2E spec
if [ ! -f "$CONTRACT" ]; then
  echo "❌ GATE BLOQUEADO: Contract não encontrado em $CONTRACT"
  echo "Execute fase 03-strategy para criar contract"
  exit 1
fi

if ! grep -q "## E2E Validation" "$CONTRACT"; then
  echo "❌ GATE BLOQUEADO: E2E Validation spec não encontrada no contract"
  exit 1
fi
```

---

## Passo 2: Carregar Playbooks

```javascript
// Carregar base E2E concepts
Read("~/.claude/commands/feature/playbooks/_e2e-base.md")

// Carregar E2E template especifico do tipo
Read("~/.claude/commands/feature/playbooks/{featureType}/e2e.md")

// Carregar contract com spec
Read({state.contract})  // path do workflow-state.json
// Extrair: e2e_type, e2e_spec
```

---

## Passo 3: Executar E2E por Tipo

### SE auto:
1. Rodar script/Playwright conforme spec
   ```bash
   {comando do spec}
   ```
2. Reportar resultado

### SE semi-auto:
1. Disparar trigger (API call conforme spec)
2. Poll resultado (max 10x, interval 5s)
   ```javascript
   for (let i = 0; i < 10; i++) {
     const result = await checkCondition();
     if (result.success) break;
     await sleep(5000);
   }
   ```
3. Verificar criterio de sucesso
4. Reportar: "E2E Semi-auto: PASSOU" ou "FALHOU: {motivo}"

### SE hybrid:
1. Solicitar acao do user:
   ```javascript
   AskUserQuestion({
     questions: [{
       question: "{acao_do_spec}. Responda quando terminar.",
       header: "Acao Manual",
       options: [
         { label: "Feito", description: "Executei a acao" },
         { label: "Nao consigo", description: "Problema ao executar" }
       ],
       multiSelect: false
     }]
   })
   ```
2. User responde "Feito"
3. Claude executa verificacoes do spec
4. Reportar: "E2E Hybrid: PASSOU" ou "FALHOU: {motivo}"

---

## Passo 4: Self-Healing Loop (SE FALHOU)

### 4.1 Classificar Falha

| Tipo | Exemplos | Acao |
|------|----------|------|
| CORRIGIVEL | Bug no código, timeout config, query errada | Corrigir automaticamente |
| EXTERNO | Rede, serviço offline, credenciais | Reportar e parar |

### 4.2 Loop Automatico (max 2 tentativas)

```
while (falhando AND tentativas < 2 AND tipo == CORRIGIVEL):
    1. Analisar causa
    2. Corrigir código/config/spec
    3. Re-run E2E
    tentativas++
```

### 4.3 Escape Hatch (SE ainda falha)

```javascript
AskUserQuestion({
  questions: [{
    question: "E2E falhou após self-healing. O que fazer?",
    header: "E2E Failed",
    options: [
      { label: "Debugar", description: "Executar /debug workflow" },
      { label: "Continuar", description: "Marcar FAILED e prosseguir" }
    ],
    multiSelect: false
  }]
})
```

---

## Passo 5: Atualizar Contract

```javascript
// Atualizar contract (path do state.contract)
// Mudar E2E Status: PENDING → PASSED | FAILED
Edit({
  file_path: {state.contract},
  old_string: "**Status:** PENDING",
  new_string: "**Status:** {PASSED | FAILED}"
})
```

---

## Gate (BLOQUEANTE)

```bash
# E2E deve ter sido executado
CONTRACT=$(jq -r '.contract' .claude/workflow-state.json)
if ! grep -q "Status:.*PASSED\|Status:.*FAILED" "$CONTRACT" 2>/dev/null; then
  echo "❌ GATE BLOQUEADO: E2E Validation não executada"
  exit 1
fi

echo "✅ Gate 07-validation passou"
```

---

## Passo 6: Atualizar Estado

```bash
jq '
  .currentPhase = "08-delivery" |
  .completedPhases += ["07-validation"] |
  .resumeHint = "E2E validado. Prox: commit e push" |
  .lastStep = "Passo 6: Atualizar Estado"
' .claude/workflow-state.json > .claude/workflow-state.tmp && mv .claude/workflow-state.tmp .claude/workflow-state.json
```

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/08-delivery.md
