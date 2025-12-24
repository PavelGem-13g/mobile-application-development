# Стратегия тестирования (Testing Model)

Цель: покрыть функциональность, UX, производительность, совместимость, безопасность (QAP «0–2»), с акцентом на автоматизацию UI и performance/load.

## 1. Уровни и виды тестов

### 1.1. Unit tests (клиент)

- Тестируются: use‑cases, маппинг ошибок, форматирование, валидация, политики кэша.
- Инструменты: Swift Testing (`import Testing`) или XCTest (выбрать один стандарт).
- Цель: быстрое покрытие доменной логики без сети/UI.

### 1.2. UI automation tests (клиент) — требование на «2 балла»

- Тестируются: критические happy‑path сценарии (UC‑01..UC‑05) и базовые ошибки.
- Инструменты: XCUITest (`mad_applicationUITests` уже есть в проекте).
- Требования:
  - Запуск тестов на CI/локально без ручных шагов.
  - Stable selectors (accessibility identifiers) для элементов UI.

### 1.3. Integration/API tests (backend)

- Тестируются: контракт API, auth/pairing, корректное проксирование через VPN к Ollama (10.8.1.3), идемпотентность/ретраи, валидация лимитов.
- Инструменты: Postman/Newman, pytest, или встроенные тесты (зависит от стека backend).
- Результат: набор сценариев, повторяемый в CI.

### 1.4. Usability tests (ручные)

- Метод: 5‑секундный тест для первого экрана + «think‑aloud» для UC‑02/UC‑04 (подключение и чат).
- Артефакты: сценарий теста, чек‑лист наблюдений, выводы и изменения UX.

## 2. Performance testing (клиент) — требование на «2 балла»

### 2.1. Измерения на iOS

- Cold start: `XCTApplicationLaunchMetric()` (уже есть шаблонный тест `testLaunchPerformance()`).
- Метрики LLM: TTFT (time-to-first-token) и время полного ответа для UC‑04, включая случаи VPN/4G.
- Streaming UI: измерить «время до появления первого фрагмента текста» и smoothness скролла (без фризов UI).
- Инструменты: XCTest Metrics + Instruments (Time Profiler, Network, Leaks).

### 2.2. Performance acceptance criteria (пример)

- p95 TTFT при 4G/VPN ≤ X секунд (X фиксируется после базового измерения).
- p95 полного ответа при 4G/VPN ≤ Y секунд (Y фиксируется после базового измерения).
- Cold start p95 ≤ Y секунд (Y фиксируется после измерения на целевом устройстве).

## 3. Load testing (backend) — желательно для «идеально»

Цель: показать понимание нагрузки и измеримость.

- Инструмент: k6/Gatling/JMeter (выбрать один).
- Сценарии:
  - LT‑01: «Чат completion» (RPS, p95 latency, error rate, concurrency) по адресу gateway 10.8.1.1.
  - LT‑02: «Streaming» (длительные соединения, обрывы, reconnect).
  - LT‑03: «List models / health check» (частые короткие запросы).
- Метрики: p50/p95/p99 latency, error‑rate, saturation (CPU/RAM/DB, сеть VPN).
- Выход: отчет + графики (Grafana) + пороги алертов.

## 4. Security checks

- Чек‑лист: OWASP MASVS L1 (как минимум: хранение секретов, сеть, логирование, jailbreak/root assumptions).
- Практика:
  - Проверка, что токены в Keychain.
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
