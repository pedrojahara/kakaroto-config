# E2E Validation - Base

## Tipos

| Tipo | Quando | Fluxo |
|------|--------|-------|
| auto | UI, scripts prontos | Comando direto |
| semi-auto | APIs, webhooks | Claude trigger + poll + verify |
| hybrid | Integracao externa | User acao + Claude verifica |

---

## Verificacoes que Claude Pode Fazer

| Tipo | Como |
|------|------|
| Database | Query conforme sintaxe do projeto |
| API | `GET /api/resource` expect 200 |
| Logs | `grep "pattern" /logs/file` |
| File | `ls /path/to/file` |

---

## Criterios de Falha

E2E FALHOU se:
1. Timeout (auto/semi-auto: 60s, hybrid: 5min)
2. Criterio de sucesso nao atingido
3. Erro inesperado
4. User: "Nao consigo" (hybrid)

---

## Recovery

SE E2E falhou:
1. Perguntar ao user se quer debugar
2. SE sim: `/debug` workflow
3. SE nao: continuar (marcar FAILED)
