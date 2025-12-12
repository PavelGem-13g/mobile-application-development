# Модель качества и чек‑лист (QAP)

Источник критериев: `MAD_Excersises/MAD_QAP_2025.md`.

## 1. Модель качества (упрощенная ISO/IEC 25010)

Измерения:

1) Functional suitability & coverage  
2) Usability & UX  
3) Performance & efficiency  
4) Stability & reliability  
5) Security & privacy  

## 2. Чек‑лист по измерениям (конкретные проверки)

### 2.1. Functional suitability & coverage

- F‑COV‑1: Есть список пользовательских сценариев (UC‑xx) и edge cases.
- F‑COV‑2: Для каждого сценария определены входы/выходы, ошибки, критерии приемки.
- F‑COV‑3: CRUD/операции синхронизации покрыты тестами (unit/integration).

### 2.2. Usability & UX

- UX‑1: Онбординг объясняет ценность и первые шаги.
- UX‑2: Навигация консистентна (одинаковые паттерны на всех экранах).
- UX‑3: Пустые состояния имеют пояснение и CTA.
- UX‑4: Ошибки не «технические», содержат действие (Retry/Settings).
- UX‑5: Доступность (VoiceOver, Dynamic Type) проверена на ключевых экранах.
- UX‑6: Есть механизм сбора UX‑feedback (CSI/NPS prompt после выполнения сценария).

### 2.3. Performance & efficiency

- PERF‑1: Измерен cold start (XCTest metrics / Instruments); есть цель/базовая линия.
- PERF‑2: Измерено время загрузки списка/деталей (p50/p95) при реальной сети.
- PERF‑3: Проверено потребление трафика (кэш, пагинация, компрессия).
- PERF‑4: Есть performance‑тест на загрузку данных «откуда‑то» (по QAP).
- PERF‑5: Есть план load‑теста backend (k6/Gatling), хотя бы в виде сценария.

### 2.4. Stability & reliability

- REL‑1: Проверены переходы background/foreground, kill&restore.
- REL‑2: Проверены условия плохой сети (loss, high latency) и корректная деградация.
- REL‑3: Есть ключевая метрика надежности + инструмент мониторинга (см. раздел 3).
- REL‑4: Crash monitoring подключен (Sentry/Crashlytics).

### 2.5. Security & privacy

- SEC‑1: TLS везде; нет hardcoded secrets.
- SEC‑2: Токены только в Keychain; logout очищает.
- SEC‑3: Минимальные permissions; прозрачное объяснение пользователю.
- SEC‑4: Логи не содержат PII и токены; включена маскировка.
- SEC‑5: Есть базовый security review по чек‑листу (OWASP MASVS L1 как ориентир).

## 3. Self‑Check (что нужно для 2 баллов)

### 3.1. Архитектурная диаграмма (0–2)

- 0: нет диаграммы
- 1: только функциональная (экраны/сценарии)
- 2: top‑level диаграмма + сеть сервисов/микросервисов, observability (см. `src/docs/architecture.md`)

### 3.2. Модель тестирования (0–2)

- 0: нет модели
- 1: только usability тест
- 2: есть automation UI + performance‑тест + план load‑тестирования (см. `src/docs/testing_strategy.md`)

### 3.3. Метрика надежности + мониторинг (0–2)

- 0: не используется
- 1: crash rate + пример monitoring tool
- 2: дополнительная(ые) метрика(и) + зрелый мониторинг (Grafana/Prometheus/Zabbix, алерты) (см. `src/docs/metrics_monitoring_feedback.md`)

### 3.4. Feedback (CSI/NPS) (0–2)

- 0: отсутствует
- 1: кнопка feedback
- 2: периодический prompt после завершения сценария + rate‑limit (см. `src/docs/metrics_monitoring_feedback.md`)

### 3.5. Запуск на устройстве (0–2)

- 0: есть только код
- 1: запускается в IDE
- 2: установлено и работает на реальном устройстве (задокументировать шаги и скрин)

