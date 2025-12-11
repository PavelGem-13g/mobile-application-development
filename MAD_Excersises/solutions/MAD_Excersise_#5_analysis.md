# MAD_Excersise #5 – Mobile Data Persistence and Offline Support

## Block 1 – Role of Persistence in Mobile Apps

This exercise explores how mobile apps store and manage data locally using databases, key-value stores, and file systems, as well as how they support offline usage and synchronization with backend services. Reliable persistence is essential for performance, user experience, and resilience to network issues.

Key motivations for local persistence:
- Faster data access and reduced network latency.
- Offline availability of critical features (reading cached content, drafting messages, viewing recent transactions).
- Lower bandwidth usage and cost for users.
- Improved perceived performance via caching and prefetching.

Understanding different storage options and their trade-offs is crucial when designing real-world mobile applications.

---

## Block 2 – Storage Options: Key-Value, SQL, and Files

Mobile platforms provide multiple persistence mechanisms, each suited to different kinds of data:

- Key-value stores (SharedPreferences/Datastore on Android, UserDefaults on iOS): ideal for small configuration values and simple flags (e.g., onboarding completed, theme setting). Not suitable for complex relational data.
- SQLite and ORM layers (Room on Android, Core Data on iOS): structured relational storage, supporting queries, relationships, and indexing for performance. Good for lists of entities (messages, products, tasks) and cached server data.
- Files and blobs: storing images, documents, or binary payloads either in app-specific directories or cache folders.

In the assignment, you typically choose an appropriate mix (e.g., key-value for settings, SQLite/Room/Core Data for domain entities, files for media) and justify these choices based on access patterns and constraints.

---

## Block 3 – Task: Designing a Local Data Model

The exercise often asks you to design tables/entities for a specific app domain, such as a notes app, todo list, news reader, or banking app.

Recommended steps:
- Identify core entities (e.g., Note, Tag, User, Transaction, Account, Article).
- For each entity, define fields, primary keys, and relationships (one-to-many, many-to-many).
- Consider indexing fields used in frequent queries (e.g., timestamps, foreign keys).

Example (Notes App):
- `Note(id, title, content, createdAt, updatedAt, isSynced)`
- `Tag(id, name)`
- `NoteTag(noteId, tagId)`

Explain how this structure supports common use-cases like listing notes by date, filtering by tag, and marking items as needing sync.

---

## Block 4 – Offline-First and Sync Strategies

A core part of the exercise is to think about offline behavior and synchronization with a backend. Offline-first design treats local data as the primary source of truth and syncs with the server opportunistically.

Key design decisions:
- Conflict resolution: last-write-wins, server-authoritative, or custom merge logic.
- Sync triggers: periodic background jobs, on-demand sync, or push-based updates.
- Change tracking: marking records as "dirty" or using version fields / timestamps.
- Error handling: retry strategies, exponential backoff, user-visible sync status.

In your analysis, describe how your app behaves under different network conditions (offline, flaky, slow) and what guarantees you offer to users (eventual consistency, local-first edits, etc.).

---

## Block 5 – Caching and Performance Considerations

Caching strategies are critical for perceived performance:
- In-memory caches (e.g., LRU cache) for frequently accessed items.
- Disk caches for images and large responses.
- Pagination and lazy loading for long lists.

Discuss how you would avoid common pitfalls:
- Stale data: ensuring caches are invalidated or refreshed when necessary.
- Over-caching: using too much memory or disk space.
- Blocking the main thread: performing database and file I/O on background threads.

Tie these considerations back to platform tools (e.g., Room with coroutines/Flow, Core Data with background contexts) and performance profiling.

---

## Block 6 – Security and Privacy

Finally, the exercise may ask you to consider security and privacy when storing data locally:
- Sensitive data (tokens, passwords, personal info) should be stored in secure storage (Android Keystore, iOS Keychain) rather than plain preferences or files.
- Use encryption-at-rest for particularly sensitive databases or files when appropriate.
- Respect privacy regulations (GDPR, etc.) by minimizing data collected and providing clear user controls for deletion.

A short reflection can explain how your persistence design balances usability, performance, and security, and what trade-offs you make for your specific app scenario.

