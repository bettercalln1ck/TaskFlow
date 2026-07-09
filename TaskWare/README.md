# TaskWare

A local-first iOS task manager built with SwiftUI. Sign up / log in, then create,
edit, complete, duplicate, delete, search, filter, and sort tasks — with insights,
local notifications, and a polished UX. All data lives on-device (Core Data); there is
no backend.

## Project setup

Requirements:

- **Xcode 26 or 27** (uses an iOS 26 deployment target).
- An **iOS 26 simulator** (e.g. iPhone 16).

Run the app:

1. Open `TaskWare.xcodeproj` in Xcode.
2. Select the **TaskWare** scheme and an iOS 26 simulator (iPhone 16).
3. Press Run (⌘R). The app launches to the **Login** screen; create an account to
   reach the dashboard.

Run the tests:

```bash
xcodebuild test -project TaskWare.xcodeproj -scheme TaskWare \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

> If two iOS runtimes are installed, `name=iPhone 16` is ambiguous — use the simulator
> UDID instead: `-destination 'platform=iOS Simulator,id=<UDID>'` (find it with
> `xcrun simctl list devices`).

There are no dependencies to install — no CocoaPods, SPM packages, or Carthage.

## Architecture overview

**MVVM + Repository + Dependency Injection**, with strictly inward-pointing layers:

```
SwiftUI Views  →  @MainActor ViewModels  →  TaskRepository (protocol)  →  Core Data
                                          →  AuthService (protocol)     →  UserDefaults
```

- **Views** (`Views/`) are pure SwiftUI and hold no business logic.
- **ViewModels** (`ViewModels/`) are `@MainActor` and drive views via `@Published`
  state; they talk to protocols only.
- **Repositories** (`Repositories/`) hide persistence behind the `TaskRepository`
  protocol. `CoreDataTaskRepository` is the app impl; `InMemoryTaskRepository` backs
  tests and previews.
- **Domain models** (`Models/`) are pure `Sendable` value types. Core Data and SwiftUI
  never leak past their layers.
- **`AppContainer`** (`App/`) is the composition root that wires concrete
  dependencies.

Async work uses Swift Concurrency (`async`/`await`); Core Data runs on background
contexts, view models on the main actor. See `ARCHITECTURE.md` for the full breakdown
and trade-offs.

## Assumptions

- Single-user, on-device only; no backend or real network. "Mock" auth means
  credentials live locally.
- Categories are a fixed enum (Work, Personal, Shopping, Health, Other), not
  user-defined.
- "Persistent login" is not real security — passwords are stored as a local
  SHA256-with-salt hash. This is a documented limitation, not a production-grade scheme.
- iOS-only (iPhone). iPad/Vision layouts are not specially designed, though the target
  permits them.

## Libraries used

**None third-party.** Only Apple system frameworks:

- **SwiftUI** — UI
- **Core Data** — persistence (programmatic model, no `.xcdatamodeld`)
- **CryptoKit** — password hashing (SHA256)
- **UserNotifications** — local due-date reminders
- **Combine** — `@Published` view-model state
- **XCTest** — tests

## Bonus features implemented

- **Undo delete** — deleting a task shows an undo snackbar that restores it.
- **Custom animations** — list diff animations, numeric-text transitions on insight
  counters, symbol-replace on the complete toggle, and a snackbar move/opacity
  transition.
- **Accessibility** — VoiceOver labels on rows, badges, and the add button; Dynamic
  Type via semantic fonts.
- **Local notifications** — due-date reminders scheduled via `UserNotifications`.

## Future improvements

- Cloud sync across devices
- User-defined categories
- Recurring tasks
- Biometric (Face ID / Touch ID) auth
- Home-screen widgets and deep linking
- Real password-reset email flow
- Richer search (details, tags, full-text)
