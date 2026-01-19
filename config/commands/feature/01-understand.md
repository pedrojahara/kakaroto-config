# Fase 1: Understand

## Responsabilidade
Coletar requisitos com o USER.

---

## Passo 0: Detectar Workflow Existente

```bash
if [ -f .claude/workflow-state.json ]; then
  phase=$(jq -r '.currentPhase' .claude/workflow-state.json 2>/dev/null)
  if [ "$phase" != "COMPLETED" ]; then
    echo "Workflow existente: $phase"
    echo "Para continuar: Read arquivo em currentPhaseFile"
    echo "Para novo: prossiga (state sera sobrescrito)"
  fi
fi
```

---

## Passo 1: Analisar Request

Identificar em $ARGUMENTS:
- Feature solicitada
- Termos-chave para busca
- Area provavel (api/, components/, services/)

---

## Passo 2: Buscar Contexto

### 2.1 Memory (sob demanda)
```
mcp__memory__search_nodes({ query: "<termos-da-feature>" })
```

### 2.2 Codebase
```
Grep: termos em <area>/
Read: arquivos diretamente relacionados
```

---

## Passo 3: Reflexao (ST)

Usar `mcp__sequential-thinking__sequentialthinking`:

1. **O que descobri** - Sintese do contexto
2. **O que ainda posso descobrir** - Gaps que consigo preencher
3. **Qual o MVP?** - Escopo MINIMO que resolve
4. **O que APENAS o user sabe** - Decisoes de produto
5. **Perguntas minimas para o user** - So o essencial

`totalThoughts`: 5

---

## Passo 4: Perguntas ao User (AUQ)

Usar `AskUserQuestion` com 2-4 perguntas consolidadas.

**Perguntas tipicas (adaptar):**
- **Problema**: Qual problema resolve? (Eficiencia/Funcionalidade/UX)
- **Escopo**: MVP ou feature completa?
- **Design**: Referencia ou patterns existentes?
- **Prioridade**: O que e mais importante?

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Qual problema principal esta feature resolve?",
      header: "Problema",
      options: [
        { label: "Eficiencia", description: "Automatizar/acelerar processo" },
        { label: "Funcionalidade", description: "Adicionar capacidade nova" },
        { label: "UX", description: "Melhorar experiencia existente" }
      ],
      multiSelect: false
    },
    // ... outras perguntas
  ]
})
```

---

## Passo 5: Criterios de Aceite (AUQ)

Coletar do user como validar sucesso/falha:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Como voce saberia que esta funcionando?",
      header: "Validacao",
      options: [
        { label: "Output especifico", description: "Retorna X, exibe Y na tela" },
        { label: "Side effect", description: "Salva no DB, posta na rede social" },
        { label: "Ausencia de erro", description: "Nao quebra, nao loga erro" }
      ],
      multiSelect: true
    },
    {
      question: "O que seria uma falha inaceitavel?",
      header: "Falha Critica",
      options: [
        { label: "Dados corrompidos", description: "Salva errado, perde dados" },
        { label: "Erro silencioso", description: "Falha sem avisar user" },
        { label: "Acao duplicada", description: "Posta 2x, cobra 2x" }
      ],
      multiSelect: true
    }
  ]
})
```

---

## Passo 6: Persistir Interview

### 6.1 Gerar slug
`{primeira-palavra}-{YYYY-MM-DD}.md`

### 6.2 Salvar
```
Write .claude/interviews/{slug}.md
```

### 6.3 Formato
```markdown
# Interview: {feature}

## Request (Passo 1)
- **Feature:** {$ARGUMENTS}
- **Area:** {api/components/services}
- **Termos-chave:** {lista}

## Descoberta (Passo 2)
- **Services:** {lista}
- **Patterns:** {lista}
- **Memory:** {entidades relevantes ou "N/A"}

## Reflexao (Passo 3)
- **Escopo:** {MVP | Completo}
- **Decisoes Implicitas:**
  | Decisao | Justificativa |
  |---------|---------------|
  | {o que assumiu} | {por que} |

## Perguntas e Respostas (Passo 4)
| # | Pergunta | Resposta | Impacto |
|---|----------|----------|---------|

## Criterios de Aceite do User (Passo 5)
| # | Criterio | Tipo | Verificacao |
|---|----------|------|-------------|
| U1 | "{criterio especifico}" | SUCESSO | {output/side-effect/ausencia} |
| U2 | "{criterio especifico}" | FALHA | {o que NAO pode acontecer} |
```

---

## Gate (BLOQUEANTE)

```bash
SLUG=$(jq -r '.feature' .claude/workflow-state.json 2>/dev/null)
[ -z "$SLUG" ] || [ "$SLUG" = "null" ] && { echo "❌ workflow-state.json sem feature definida"; exit 1; }

INTERVIEW=".claude/interviews/${SLUG}.md"

test -f "$INTERVIEW" || { echo "❌ Interview não encontrada: $INTERVIEW"; exit 1; }

# Seções obrigatórias (ordem do fluxo)
grep -q "## Request" "$INTERVIEW" || { echo "❌ Interview sem Request"; exit 1; }
grep -q "## Descoberta" "$INTERVIEW" || { echo "❌ Interview sem Descoberta"; exit 1; }
grep -q "## Perguntas e Respostas" "$INTERVIEW" || { echo "❌ Interview sem Q&A"; exit 1; }
grep -q "## Criterios de Aceite do User" "$INTERVIEW" || { echo "❌ Interview sem Criterios"; exit 1; }

# Validar que Critérios tem conteúdo (não apenas header)
grep -A1 "## Criterios de Aceite do User" "$INTERVIEW" | grep -q "| U" || { echo "❌ Criterios sem entradas (precisa U1, U2...)"; exit 1; }

echo "✅ Gate 01-understand passou"
```

---

## Passo 7: Persistir Estado do Workflow

```bash
mkdir -p .claude
cat > .claude/workflow-state.json << 'EOF'
{
  "workflow": "feature",
  "feature": "${FEATURE_SLUG}",
  "currentPhase": "02-analyze",
  "completedPhases": ["01-understand"],
  "startedAt": "${TIMESTAMP}",
  "resumeHint": "Interview coletada. Prox: triage tipo (api/ui/service/job) e carregar playbook",
  "lastStep": "Passo 7: Persistir Estado",
  "interview": ".claude/interviews/${FEATURE_SLUG}.md",
  "analysis": null,
  "contract": null
}
EOF
```

**Nota:** Substituir `${FEATURE_SLUG}` pelo slug real e `${TIMESTAMP}` por `date -u +%Y-%m-%dT%H:%M:%SZ`

---

## PROXIMA FASE
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/02-analyze.md
