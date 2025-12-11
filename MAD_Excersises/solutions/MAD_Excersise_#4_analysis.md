# MAD_Excersise #4 – Mobile App Architecture & Patterns

## Block 1 – Motivation for Mobile Architectures

This exercise focuses on structuring mobile applications using established architectural patterns such as MVC, MVP, MVVM, Clean Architecture, and layered designs. As mobile apps grow in complexity, ad-hoc "all-in-Activity" or "massive ViewController" designs quickly become unmaintainable. Architecture ensures separation of concerns, testability, and easier evolution of features.

Key motivations:
- Decoupling UI from business logic and data access.
- Enabling unit testing without full UI or platform dependencies.
- Making code easier to reason about for teams over time.
- Supporting modularization and reuse of core logic.

Understanding why these patterns emerged in Android and iOS ecosystems helps you choose appropriate designs instead of blindly following templates.

---

## Block 2 – Common Mobile Architectures (MVC, MVP, MVVM)

Most mobile architectures can be viewed as variations of how responsibilities are split among UI, presentation, and domain layers.

- MVC (Model–View–Controller): classic pattern where Model holds data/business logic, View displays data, and Controller coordinates interactions. On iOS, UIKit historically pushed a ViewController-centric style that often degenerated into "Massive View Controllers" when too much logic was placed in controllers.
- MVP (Model–View–Presenter): separates presentation logic into a Presenter that communicates with a passive View (interface) and the Model. This became popular on Android to reduce coupling to `Activity`/`Fragment` lifecycles and improve testability.
- MVVM (Model–View–ViewModel): further decouples View from logic by introducing ViewModel that exposes observable state (e.g., LiveData, StateFlow) consumed by the View. It fits well with data-binding and reactive UI frameworks (Jetpack Compose, SwiftUI).

In your exercise, you should compare these patterns in terms of testability, complexity, and suitability for your chosen platform and app domain.

---

## Block 3 – Clean Architecture and Layered Design

Clean Architecture (inspired by Robert C. Martin) and similar layered designs (presentation, domain, data layers) are widely used in modern mobile apps.

Typical layers:
- Presentation: Activities, Fragments, ViewControllers, Composables, SwiftUI Views, Presenters, or ViewModels. Responsible for rendering UI and handling user input.
- Domain: use cases/interactors and domain models that encapsulate business rules independent of frameworks.
- Data: repositories, data sources, and API/DB access (e.g., Retrofit, Room, Core Data) that provide data to the domain layer.

Core principles:
- Dependency inversion: outer layers depend on inner abstractions (interfaces), not vice versa.
- Framework independence: domain logic should not depend directly on Android/iOS SDK classes.
- Testability: domain and data logic can be unit-tested in isolation.

In the assignment, mapping this to your app means defining clear boundaries (e.g., `UserRepository`, `GetUserProfileUseCase`, `UserProfileViewModel`) and explaining how data flows between layers.

---

## Block 4 – Task: Designing Architecture for a Sample App

The exercise typically asks you to pick a mobile app scenario (e.g., news reader, todo list, weather app, banking app) and design an architecture for it.

Recommended steps:
- Identify main features/screens: list view, detail view, forms, authentication.
- Choose a pattern (MVVM + Clean, MVP, or well-structured MVC) consistent with your platform.
- Define key components: View/ViewController, ViewModel/Presenter, UseCases/Interactors, Repositories, DataSources.
- Describe responsibilities and dependencies between components.

Example (News App):
- `NewsListView` ↔ `NewsListViewModel` ↔ `GetNewsHeadlinesUseCase` ↔ `NewsRepository` ↔ `RemoteNewsDataSource` / `LocalCache`.

Document how this design supports offline caching, error handling, and feature evolution.

---

## Block 5 – Reactive and Asynchronous Patterns

Modern mobile apps depend heavily on asynchronous operations: network calls, database I/O, background tasks, and UI updates.

Important patterns and tools:
- Coroutines/Flows (Kotlin), async/await and Combine (Swift), RxJava/RxSwift.
- Observables and streams for UI state (LiveData, StateFlow, SharedFlow, SwiftUI `@State` and `@Published`).
- Background work managers (WorkManager, BGTaskScheduler) for deferred tasks.

Your analysis should explain how these fit into your chosen architecture. For example, ViewModels exposing `StateFlow` or `LiveData` that the view observes, while use cases run on background dispatchers and repositories handle I/O.

---

## Block 6 – Evaluation and Trade-offs

Finally, the exercise usually asks you to justify your design and reflect on trade-offs:
- Complexity vs. simplicity: when a full Clean Architecture is justified vs. when a lightweight MVVM setup is enough.
- Learning curve for the team and consistency with existing codebase.
- Test coverage and ease of debugging.

A short reflection can discuss how your architecture would handle future requirements like offline support, feature flags, A/B testing, and modularization into feature modules.

