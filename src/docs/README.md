# Документация (MAD Application)

Эта папка содержит требования и архитектурные артефакты для мобильного приложения на базе `src/app/mad_application` с фокусом на критерии качества из `MAD_Excersises/MAD_QAP_2025.md`.

Предметная область: мобильное приложение обращается к LLM, запущенной на домашнем компьютере пользователя (Ollama), через безопасное сетевое соединение.

- `src/docs/requirements_system.md` — требования ко всей системе (функциональные/нефункциональные, критерии приемки).
- `src/docs/requirements_components.md` — требования к подсистемам (мобильный клиент, backend, данные, аналитика, мониторинг, feedback).
- `src/docs/architecture.md` — общая архитектура, диаграммы (включая сетевую связность сервисов/микросервисов).
- `src/docs/quality_model_and_checklist.md` — модель качества + чек‑лист для self-check (0–2) по каждому измерению.
- `src/docs/testing_strategy.md` — модель тестирования (в т.ч. UI automation, performance, load).
- `src/docs/metrics_monitoring_feedback.md` — метрики надежности/качества, мониторинг, сбор обратной связи (CSI/NPS).

Помимо документов в `src/docs`, артефакты реализации располагаются здесь же (папка `/src`):

- `src/home_gateway` — FastAPI gateway (Dockerfile, requirements, README).
- `src/docker-compose.yml` — пример сборки домашнего gateway.
- `src/app/mad_application` — iOS клиент с экраном подключения и чата.

Примечание: документы ориентированы на демонстрацию качества (QAP): top-level архитектура с сетью сервисов, модель тестирования (включая UI automation и performance), метрики/мониторинг и сбор feedback.
