# Home Gateway (FastAPI)

Домашний gateway/BFF, который:

- принимает запросы от мобильного клиента,
- проверяет токен доступа и лимиты,
- проксирует запросы к локально установленной Ollama (`/api/tags`, `/api/chat`),
- умеет возвращать потоковые ответы (SSE/NDJSON) и обычные JSON ответы.

## Основные переменные окружения

| Переменная | Назначение | Значение по умолчанию |
|------------|------------|-----------------------|
| `OLLAMA_BASE_URL` | Базовый URL Ollama внутри VPN (по сценарию 10.8.1.3:11434) | `http://10.8.1.3:11434` |
| `GATEWAY_SHARED_TOKEN` | Токен, который клиент должен передавать в `Authorization: Bearer ...` | пусто (dev режим) |
| `RATE_LIMIT_REQUESTS` | Сколько запросов разрешено за `RATE_LIMIT_WINDOW_SEC` для одного IP | `20` |
| `RATE_LIMIT_WINDOW_SEC` | Размер окна (сек) для rate limiting | `60` |

## Запуск

```bash
cd src/home_gateway
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export OLLAMA_BASE_URL=http://10.8.1.3:11434
export GATEWAY_SHARED_TOKEN=super-secret
uvicorn app.main:app --reload
```

### Docker

```bash
cd src
docker compose up --build home_gateway
```

См. `../docker-compose.yml` для примера.
