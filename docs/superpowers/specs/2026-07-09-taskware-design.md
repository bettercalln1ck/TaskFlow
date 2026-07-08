# TaskWare — Design Spec

**Date:** 2026-07-09
**Status:** Approved (design phase)

A local-first task management app for iOS built with SwiftUI, MVVM, the Repository
pattern, and dependency injection. Persistence is Core Data; async work uses Swift
Concurrency (async/await). No third-party dependencies.

---

## 1. Goals & Constraints

**Functional goals** (from brief): authentication (login / sign up / mock forgot
password / persistent session), a dashboard listing all tasks, full task CRUD plus
complete-toggle and duplicate, search/filter/sort, local persistence that survives
restarts, dashboard insights, and a polished UX (loading / empty / error states,
pull-to-refresh, dark mode).

**Non-functional goals:** responsive with 1,000+ tasks; clean, testable architecture;
unit tests for task creation, validation, and the repository layer.

**Bonus features to implement (all four selected):** Undo Delete, custom animations,
accessibility improvements, local notifications.

**Environment constraints / decisions:**

- Toolchain: **Xcode 27.0** (`/Applications/Xcode-beta.app`), iOS 27 SDK, iOS 27
  simulators. Driven headlessly via `DEVELOPER_DIR=...` + `xcodebuild` — no `sudo
  xcode-select` required. This means the app **and** its test target can be built and
  run for verification.
- Project format is `objectVersion 90` with a **`PBXFileSystemSynchronizedRootGroup`**:
  any `.swift` file placed inside `TaskWare/TaskWare/` is auto-compiled into the app —
  no `.pbxproj` editing to add app sources.
- Build settings of note: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
  `SWIFT_APPROACHABLE_CONCURRENCY = YES`, Swift 6.2 compiler. Code is written
  concurrency-clean with explicit isolation.
- App name is **TaskWare** (matches the provided scaffold), fulfilling the "TaskFlow"
  brief.
- **Commits are the user's responsibility** — this process writes files but does not
  commit.
- Deployment target lowered from `27.0` to **`26.0`** for realistic device coverage
  (still builds/runs on the iOS 27 simulator).

---

## 2. Architecture Overview

MVVM + Repository + lightweight DI. Strict layering, dependencies point inward:

```
Views (SwiftUI)  →  ViewModels (@MainActor)  →  Repository protocol  →  Core Data
                                              →  Services (auth, insights, notifications)
```

- **Views** are declarative and stateless beyond view-local UI state; they observe a
  ViewModel and send user intents to it.
- **ViewModels** are `@MainActor`, expose `@Published` state, and orchestrate async
  calls. They depend only on **protocols**, never on Core Data types.
- **Repositories** hide persistence behind `TaskRepository`. `CoreDataTaskRepository`
  is the production implementation; `InMemoryTaskRepository` backs previews and tests.
- **Services** are single-purpose: `AuthService` (mock/local), insights computation,
  filtering/sorting/search, and notification scheduling.
- **DI**: an `AppContainer` composition root constructs concrete dependencies once and
  injects them. No third-party DI framework.

### Folder structure

```
TaskWare/
├── TaskWare.xcodeproj
├── TaskWare/                      ← app target (synchronized folder)
│   ├── App/                       ← TaskWareApp (@main), AppContainer (DI), RootView routing
│   ├── Models/                    ← Task, Priority, Status, Category, User (Sendable value types)
│   ├── Persistence/               ← CoreDataStack, programmatic NSManagedObjectModel, mapping
│   ├── Repositories/              ← TaskRepository (protocol), CoreDataTaskRepository, InMemoryTaskRepository
│   ├── Services/                  ← AuthService, SessionStore, InsightsService, TaskQueryService, NotificationService
│   ├── ViewModels/                ← AuthViewModel, DashboardViewModel, TaskEditorViewModel
│   ├── Views/
│   │   ├── Auth/                  ← Login, SignUp, ForgotPassword
│   │   ├── Dashboard/             ← Dashboard list, filter/sort bar, insights header
│   │   ├── TaskEditor/            ← Create/Edit form
│   │   └── Components/            ← reusable: TaskRow, PriorityBadge, StatusChip, EmptyStateView, ErrorStateView, LoadingView, UndoSnackbar
│   └── Support/                   ← extensions, theme, date helpers
└── TaskWareTests/                 ← XCTest target (added via verified pbxproj edit)
```

---

## 3. Domain Model

Value types (structs), `Sendable`, `Identifiable`, `Equatable`. Core Data managed
objects exist only inside the persistence layer and are mapped to/from these.

```
Task
  id: UUID
  title: String
  details: String            // "description" is reserved-ish; use `details`
  dueDate: Date?
  priority: Priority         // .low / .medium / .high
  status: Status             // .pending / .completed
  category: Category         // enum with a fixed set (Work, Personal, Shopping, Health, Other)
  createdAt: Date
  updatedAt: Date

Priority: enum, Comparable (for sort), CaseIterable
Status:   enum, CaseIterable
Category: enum, CaseIterable, with display name + system icon
User:     id, email, displayName   (mock auth)
```

Derived: a task is **overdue** when `status == .pending && dueDate != nil && dueDate <
now`. Computed at query time, not stored.

---

## 4. Persistence — Core Data

- **`CoreDataStack`** owns an `NSPersistentContainer` built from a **programmatic
  `NSManagedObjectModel`** (one `TaskEntity`). Avoids needing the Xcode model editor
  and keeps everything in the synchronized folder.
- A single `TaskEntity` with attributes mirroring `Task`. `category`/`priority`/`status`
  stored as `String`/`Int16` raw values.
- **`CoreDataTaskRepository`** performs work on a background context via
  `container.performBackgroundTask` and returns mapped value structs; reads use
  `NSFetchRequest` with predicates + sort descriptors so filtering/sorting happen in the
  store, not in memory — this is what keeps 1,000+ tasks responsive.
- Store persists to the app's Application Support directory → survives restarts.
- Tests use an in-memory store (`NSPersistentStoreDescription` with
  `/dev/null` URL / `NSInMemoryStoreType`).

---

## 5. Features → Components

| Requirement | Where it lives |
|---|---|
| Login / Sign Up / Forgot Password | `Views/Auth/*`, `AuthViewModel`, `AuthService` |
| Persistent login session | `SessionStore` (persists current user id to UserDefaults/Keychain-lite), checked at launch by `RootView` |
| Dashboard list of tasks | `DashboardView` + `DashboardViewModel` |
| Create / Edit task | `TaskEditorView` + `TaskEditorViewModel` (shared for both modes) |
| Delete + Undo | swipe action → repository delete; `UndoSnackbar` holds a snapshot and re-inserts on undo |
| Mark completed | row toggle → `repository.setStatus` |
| Duplicate | `Task.duplicated()` (new id, `.pending`, fresh timestamps, " (copy)" title) → insert |
| Search by title | `TaskQueryService` / predicate |
| Filter by category, status | filter bar bound to `DashboardViewModel` query state |
| Sort by due date, priority | sort control → sort descriptors |
| Insights (total/completed/pending/overdue) | `InsightsService`, shown in dashboard header |
| Loading / empty / error states | `LoadingView`, `EmptyStateView`, `ErrorStateView` driven by a `ViewState` enum |
| Pull-to-refresh | `.refreshable` on the list → `viewModel.refresh()` |
| Dark mode | semantic colors + a `Theme`; respects system appearance |

**Auth semantics (mock):** Sign Up stores a user (email + hashed-ish password) locally.
Login validates against stored users. Forgot Password shows a mock confirmation flow
(no email actually sent). Session persistence keeps the user logged in across launches
until explicit logout.

**Query model:** `DashboardViewModel` holds a `TaskQuery { searchText, category?,
status?, sort }`. Changing any control rebuilds the query and re-fetches. This keeps the
list a pure function of query + store.

---

## 6. Concurrency & State

- ViewModels are `@MainActor`; repository methods are `async` and hop to background
  contexts internally.
- View state modeled as `enum ViewState<T> { case idle, loading, loaded(T), empty,
  error(Message) }` so loading/empty/error UX is uniform and testable.
- No Combine; Swift Concurrency throughout. `@Published` + `ObservableObject` for view
  binding.

---

## 7. Testing Strategy

Target: **`TaskWareTests`** (XCTest), run via `xcodebuild test` on an iOS 27 simulator.

- **Model / creation**: `Task` factory + `duplicated()` behavior.
- **Validation**: `TaskValidator` — empty/whitespace title rejected, title length cap,
  optional due date, past-due allowed but flagged.
- **Repository**: CRUD, toggle status, delete/undo round-trip, filter+sort+search
  correctness against `InMemoryTaskRepository`; a Core Data variant using an in-memory
  store to prove the mapping and predicates.
- **Insights**: counts (total/completed/pending/overdue) over a known fixture set,
  including overdue edge cases (no due date, due exactly now, completed-but-past).

Verification loop: `xcodebuild -list` to confirm the target, then `xcodebuild test`
until green. A 1,000-task seed (debug-only) sanity-checks responsiveness.

---

## 8. Bonus Features

- **Undo Delete** — delete removes the row immediately and shows an `UndoSnackbar` for
  ~5s holding the deleted snapshot; undo re-inserts, timeout finalizes.
- **Custom animations** — animated list insert/delete, completion check animation,
  snackbar slide, insight count transitions (`withAnimation`, `matchedGeometryEffect`
  where it earns its place).
- **Accessibility** — VoiceOver labels/traits on rows and controls, Dynamic Type via
  semantic fonts, sufficient contrast in both appearances, accessible tap targets.
- **Local notifications** — `NotificationService` requests authorization at runtime and
  schedules a due-date reminder when a task with a future due date is saved; cancels on
  completion/delete. No entitlement or pbxproj change required for local notifications.

---

## 9. Deliverables

- Complete, buildable Xcode project (app + test target).
- Passing unit tests (`xcodebuild test`).
- `README.md`: setup, architecture overview, assumptions, libraries (none), future
  improvements.
- `ARCHITECTURE.md`: layer diagram + trade-off discussion (Core Data vs alternatives,
  MVVM boundaries, DI approach, performance approach).
- Out of scope for this environment (user handles): demo video, TestFlight/IPA build.

---

## 10. Assumptions

- Single-user, on-device only; no backend or real network. "Mock" auth means
  credentials live locally.
- Categories are a fixed enum (not user-defined) — YAGNI for the brief.
- "Persistent login" does not imply real security; passwords are stored with a simple
  hash locally and this limitation is documented, not productionized.
- iOS-only (iPhone); iPad/Vision layouts are not specially designed though the target
  allows them.

---

## 11. Explicitly Out of Scope (YAGNI)

User-defined categories, task sharing/collaboration, cloud sync, recurring tasks,
attachments, real password reset email, biometric auth, widgets, deep linking (not among
the two-bonus requirement we chose).
