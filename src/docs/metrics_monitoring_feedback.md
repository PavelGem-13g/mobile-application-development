# Метрики, мониторинг и обратная связь

Цель: выполнить QAP пункты про (1) количественные метрики, (2) ключевую метрику надежности и инструмент мониторинга, (3) сбор feedback (CSI/NPS) с prompt после завершения сценария.

## 1. Ключевые метрики (KPI/SLI)

### 1.1. Надежность (ключевая контролируемая метрика)

Выбрать 1 «ключевую» (для self-check) и 2–3 вспомогательных:

- Key metric (MVP): **Success rate запросов чата** (`gateway_http_requests_total` по `/chat`).
- Вспомогательные:
  - API error rate (5xx/4xx/429) по endpoint’ам gateway.
  - Средняя задержка `/models` и `/chat` (latency ms).
  - Доля успешных завершений ключевого сценария (chat_request ok).
  - Длительность сессии клиента (event `session_duration`).

Инструменты мониторинга (факт реализации):

- Для клиента: отправка событий и метрик на gateway (`/client-metrics`).
- Для backend/инфры: Prometheus + Grafana (метрики), HTML dashboard `/dashboard` для быстрой проверки.
- Альтернатива/дополнение: Zabbix для инфраструктурных метрик и алертов (не развернут).

### 1.2. Производительность

- Cold start измеряется в UI/perf тестах.
- Время ответа `/models` и `/chat` фиксируется gateway и клиентом (`models_fetch`, `chat_request`).
- Длительность сессии (`session_duration`) и частота действий (тапы).

### 1.3. UX/продукт

- Session length (event `session_duration`).
- Конверсия в «успешное завершение сценария» (`chat_request` status).
- CSI 1–5 по сценарию `chat_completed`.

## 2. Дашборды и визуализация

- Dashboard‑1 (Grafana): RPS, средняя latency, client‑events, feedback (см. `src/docs/images/dashboard/Grafana.png`).
- Dashboard‑2 (Prometheus): live‑query метрик gateway (см. `src/docs/images/dashboard/Prometheus.png`).
- Dashboard‑3 (HTML): быстрый overview на `/dashboard` (см. `src/docs/images/dashboard/Metrics.png`).

Алерты (пример, для Prometheus/Grafana):

- Error rate > T% за 5 минут.
- p95 TTFT > X ms за 10 минут.
- Доля 401/403 растет (проблемы с токеном/pairing).
- Crash‑free sessions < Y% за сутки.
- WireGuard handshake отсутствует > N минут (домашний ПК недоступен).

## 3. Сбор обратной связи (CSI/NPS)

### 3.1. Каналы

- Prompt после завершения ключевого сценария (chat) с задержкой 10 секунд.
- UI‑форма: оценка 1–5 + комментарий (см. `src/docs/images/feedback/user_satisfaction.png`).

### 3.2. Правила показа prompt (факт реализации)

- Показывается после получения ответа (по событию `responseText`).
- Задержка 10 секунд перед показом.
- Ограничений по частоте нет (можно добавить при необходимости).

### 3.3. Что сохранять (privacy-friendly)

- Оценка (CSI 1–5) + комментарий (опционально).
- Контекст: сценарий (`chat_completed`), timestamp.
- PII не сохраняются.

## 4. Процесс улучшений (замкнутый цикл)

1) Собрать метрики/feedback → 2) Найти топ‑проблемы → 3) Завести задачи → 4) Исправить → 5) Повторно измерить.

Артефакты для защиты/оценки:

- Скриншоты дашбордов (Grafana/Prometheus/HTML).
- Пример алерта и его разбор.
- Короткий отчет «до/после» по 1–2 метрикам.

## 5. Реализация (endpoint’ы)

- `POST /client-metrics` — события и метрики клиента (тапы, session_duration, chat_request).
- `POST /feedback` — оценки 1–5 + комментарий.
- `GET /feedback/summary` — агрегаты (avg, count).
- `GET /metrics` — Prometheus scrape.
- `GET /dashboard` — HTML‑дашборд.
