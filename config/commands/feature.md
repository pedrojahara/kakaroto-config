---
model: opus
---
# Feature Workflow v2

Desenvolver: $ARGUMENTS

## INICIAR
ACAO OBRIGATORIA: Read ~/.claude/commands/feature/01-understand.md
Seguir instrucoes. Cada fase aponta para a proxima.

## Fluxo

```
01-understand (requisitos)
    ↓ User responde perguntas de PRODUTO
02-analyze (interna - triage + playbook)
    ↓ Automatico
03-strategy ← UNICA APROVACAO
    ↓ User aprova estrategia de testes
04-red (RED)
    ↓ Automatico
05-green (GREEN)
    ↓ Automatico
06-quality (REFACTOR)
    ↓ Automatico
07-validation (E2E)
    ↓ Automatico
08-delivery (commit)
    ↓ Automatico
09-evaluate (auto-avaliacao)
```

## Fases

| Fase | Responsabilidade | Aprovacao? |
|------|------------------|------------|
| 01-understand | Coletar requisitos de produto | User responde |
| 02-analyze | Triage + playbook (interna) | Automatico |
| 03-strategy | Aprovar estrategia de testes | **USER APROVA** |
| 04-red | Escrever testes RED | Automatico |
| 05-green | Código mínimo GREEN | Automatico |
| 06-quality | REFACTOR + Quality Gate | Automatico |
| 07-validation | E2E Validation | Automatico |
| 08-delivery | Commit + Push + Memory Sync | Automatico |
| 09-evaluate | Auto-avaliacao + melhorias | Automatico |
