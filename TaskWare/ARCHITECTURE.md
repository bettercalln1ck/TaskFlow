# TaskWare — Architecture

## Layer diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Views (SwiftUI)                                              │
│  LoginView, SignUpView, DashboardView, TaskEditorView, …      │
│  Pure UI. No business logic.                                  │
└───────────────┬───────────────────────────────────────────────┘
                │ binds to @Published state
┌───────────────▼───────────────────────────────────────────────┐
│  ViewModels (@MainActor)                                       │
│  AuthViewModel, DashboardViewModel, TaskEditorViewModel        │
│  Orchestrate use-cases, expose ViewState, depend on protocols. │
└───────┬────────────────────────────────┬──────────────────────┘
        │ TaskRepository (protocol)       │ AuthService (protocol)
┌───────▼──────────────────┐   ┌──────────▼──────────────────────┐
│ CoreDataTaskRepository    │   │ LocalAuthService                 │
│ InMemoryTaskRepository    │   │   → AuthStore (UserDefaults/     │
│   (tests/previews)        │   │      in-memory), PasswordHasher  │
└───────┬───────────────────┘   └──────────────────────────────────┘
        │
┌───────▼───────────────────┐
│ CoreDataStack             │  programmatic NSManagedObjectModel
│ (background contexts)     │
└───────────────────────────┘

Composition root: AppContainer (App/) constructs and wires the concrete
dependencies once, then hands protocols to the view models.

Domain models (Models/): TaskItem, User, TaskPriority/Status/Category —
pure Sendable value types shared across layers. Persistence and SwiftUI
types never cross a layer boundary.
```

## Why Core Data

Core Data is the mature, first-party persistence framework with mature query support
(`NSFetchRequest` predicates + sort descriptors), background contexts, and no external
dependency. SwiftData was considered but is newer and less battle-tested for the query
and concurrency patterns here; a hand-rolled store would reinvent indexing, fetching,
and change management for no benefit. Core Data pushes filtering and sorting into the
store, which matters for the 1,000-task performance target.

**Quirk — programmatic model.** The model is built in code (`TaskModel.makeModel()` in
`Persistence/TaskEntity.swift`) instead of a `.xcdatamodeld` editor file. This keeps the
schema readable in source, diffable in review, and free of a binary editor artifact. The
single `TaskEntity` has a uniqueness constraint on `id`.

## Repository boundary and testability

`TaskRepository` is a narrow protocol (`fetchAll`, `fetch(_:)`, `task(with:)`, `create`,
`update`, `delete`). View models depend only on it, so:

- Production wires `CoreDataTaskRepository`.
- Tests and previews wire `InMemoryTaskRepository` — an `actor` with a dictionary store,
  no disk, no setup.

The same seam applies to auth: `AuthService`/`AuthStore` protocols let tests use
`InMemoryAuthStore` instead of `UserDefaults`.

## Dependency injection

`AppContainer` (`@MainActor`) is the single composition root. Its default `init()`
constructs the real stack (`CoreDataStack`, `CoreDataTaskRepository`,
`UserDefaultsAuthStore`, `LocalAuthService`, `NotificationService`). A second
initializer takes all dependencies explicitly — the test/preview seam. No service
locator, no globals.

## Query parity: TaskQueryEngine vs Core Data predicates

`TaskQueryEngine` is the **reference** implementation of search/filter/sort over an
in-memory `[TaskItem]`. `CoreDataTaskRepository` mirrors it with `NSPredicate` +
`NSSortDescriptor` so filtering and sorting happen in-store.

**Documented divergence:** for `.dueDateAscending`, `TaskQueryEngine` sorts tasks with a
`nil` due date **last**, whereas the Core Data path (a plain `NSSortDescriptor` on
`dueDate`) sorts `nil` **first**. This is an accepted trade-off for the store path — a
custom nil-handling sort would mean fetching and re-sorting in memory, defeating the
in-store performance goal. Tests avoid mixing nil due dates into a sorted assertion set.

## Concurrency model

- **View models are `@MainActor`** — all UI-facing state mutates on the main actor.
- **Repositories run off the main actor.** `CoreDataTaskRepository` is
  `@unchecked Sendable` and performs work on `performBackgroundTask` contexts, bridged to
  `async`/`await` via `withCheckedThrowingContinuation`. `InMemoryTaskRepository` is an
  `actor`.
- Default actor isolation is `MainActor`; `Sendable` value types and off-main types are
  marked `nonisolated`/`@unchecked Sendable` where required. The in-memory Core Data
  store used in tests loads with a `/dev/null`-style in-memory store type so runs are
  isolated and disk-free.

## Performance approach

- Filtering and sorting are pushed into Core Data (predicates + sort descriptors), not
  done in memory after fetch.
- `DebugSeeder` (`Support/DebugSeeder.swift`) seeds 1,000 tasks via a `#if DEBUG` menu
  action in the dashboard to validate list and query performance at scale.

## Trade-offs and known limitations

- **Mock auth is not secure.** Passwords are stored as SHA256(salt + password) in
  `UserDefaults`. There is no keychain, no rate limiting, no server. It satisfies the
  "persistent login" brief but is explicitly not production-grade.
- **Fixed categories.** `TaskCategory` is a compile-time enum (Work, Personal, Shopping,
  Health, Other). User-defined categories are out of scope (YAGNI).
- **Password reset is mocked** — it only verifies the account exists; no email is sent.
- **iOS/iPhone-focused.** iPad/Vision layouts are not specifically designed.
- **The nil-dueDate sort divergence** between the engine and the store, described above.
