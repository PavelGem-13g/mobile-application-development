# Стратегия тестирования (Testing Model)

Цель: покрыть функциональность, UX, производительность, совместимость, безопасность (QAP «0–2»), с акцентом на автоматизацию UI и performance/load.

## 1. Уровни и виды тестов

### 1.1. Unit tests (клиент)

- Реализация: `src/app/mad_application/mad_applicationTests/mad_applicationTests.swift`.
- Покрыто: маппинг HTTP ошибок (`HTTPErrorMapper`).
- Инструмент: Swift Testing (`import Testing`).

### 1.2. UI automation tests (клиент) — требование на «2 балла»

- Реализация: `src/app/mad_application/mad_applicationUITests/mad_applicationUITests.swift`.
- Сценарии: happy‑path, валидация пустого промпта, performance refresh models.
- Используются стабильные accessibility identifiers.
- Скриншот: `src/docs/images/autotests/complete_all_tests.png`.
- Видео на устройстве: `src/docs/images/autotests/device_test.MP4`.

### 1.3. Integration/API tests (backend)

- Статус: не реализовано; предусмотрены endpoint’ы `/health`, `/models`, `/chat`, `/metrics`.

### 1.4. Usability tests (ручные)

- Метод: 5‑секундный тест первого экрана + «think‑aloud» для UC‑02/UC‑04.
- Артефакты: feedback prompt (см. `src/docs/images/feedback/user_satisfaction.png`).

## 2. Performance testing (клиент) — требование на «2 балла»

### 2.1. Измерения на iOS

- Cold start: `XCTApplicationLaunchMetric()` в `mad_applicationUITests.swift`.
- Performance refresh models: `XCTClockMetric()` в UI тестах.
- Метрики чата и моделей собираются на gateway (`/metrics`) и клиентом (`/client-metrics`).

### 2.2. Performance acceptance criteria (пример)

- p95 latency `/chat` ≤ X секунд (X фиксируется после базового измерения).
- Cold start p95 ≤ Y секунд.

## 3. Load testing (backend) — желательно для «идеально»

Цель: показать понимание нагрузки и измеримость.

- Инструмент: k6/Gatling/JMeter (планируется).
- Сценарии:
  - LT‑01: «Чат completion» (RPS, p95 latency, error rate, concurrency) по адресу gateway 10.8.1.1.
  - LT‑02: «Streaming» (длительные соединения, обрывы, reconnect).
  - LT‑03: «List models / health check» (частые короткие запросы).
- Метрики: p50/p95/p99 latency, error‑rate, saturation (CPU/RAM/DB, сеть VPN).
- Выход: отчет + графики (Grafana) + пороги алертов.

## 4. Security checks

- Чек‑лист: OWASP MASVS L1 (как минимум: хранение секретов, сеть, логирование, jailbreak/root assumptions).
- Практика:
- Проверка: токены пока хранятся в `AppStorage` (запланировано перенести в Keychain).
  - Проверка, что нет PII/токенов в логах.
  - Проверка ATS/HTTPS.
  - Проверка, что Ollama не доступна напрямую из интернета (только LAN/через gateway/VPN).
  - Проверка rate limit/лимитов размера промпта на gateway.

## 5. Compatibility testing

- Матрица: минимум 2 устройства/симулятора (малый/большой экран) + минимум 1 реальное устройство.
- Проверки: ориентации, Dynamic Type, темная тема, локаль.

## 6. Трассируемость «требование → тест»

Требования из `src/docs/requirements_system.md` должны иметь ссылки на:

- Unit/UI тесты (для клиента) и/или API тесты (для backend),
- ручные проверки usability,
- performance измерения.
