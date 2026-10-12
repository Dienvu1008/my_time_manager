# Architecture Refactor Report — My Time Manager

**Scope:** Introduce a domain boundary between the UI/state layer and the SQLite
persistence layer, so that every UI/Bloc/Controller goes through domain
repositories and domain services instead of calling `DatabaseManager` directly —
making the codebase ready for a future AI agent to drive the same capabilities.

> **Known residual (noted during roadmap reconciliation):** the UI/Bloc/Controller
> layer no longer calls `DatabaseManager` directly, but `DatabaseManager` itself
> still invokes `NotificationService` from `insertTimeInterval` /
> `updateTimeInterval` / `deleteTimeInterval`. "No notification side effects in
> low-level persistence" is therefore not yet satisfied; it is resolved in **Core
> Track Phase R** (see `docs/architecture/roadmap.md`).

**Hard constraints honored throughout:**

- No AI / Ollama / llama.cpp / Rust / AI dependencies were added.
- `DatabaseManager` implementation, **schema, migrations, triggers, backup
  format, and sync semantics were left unchanged.**
- Migration was done as small vertical slices, verifying after each.
- Behavior preserved (no user-visible change).

---

## 1. Current architecture (after refactor)

```
UI (screens / component_widgets / view)
        │  depends only on domain abstractions (context.read / constructor injection)
State management (BLoC / Cubit / ChangeNotifier)
        │
Domain layer  (lib/domain)
   ├─ Repository interfaces
   └─ Domain services (business rules)
        │  implemented by
Data layer  (lib/data/repositories)  — Sqlite* adapters, 1:1 delegation
        │
DatabaseManager  (lib/data/database)  — UNCHANGED
        │
SQLite (sqflite / sqflite_common_ffi)
```

Dependency injection: a single `MultiRepositoryProvider` in `lib/app/app.dart`
provides every repository and service app-wide. Blocs/controllers take them via
constructor injection; widgets read them with `context.read<...>()`.

---

## 2. Problems found (before refactor)

- UI widgets, Blocs, and controllers called the `DatabaseManager()` singleton
  directly and in scattered places, coupling presentation to persistence.
- Business rules lived **inside widgets**: toggling completion, updating
  measurable progress, and recurrence expansion (`_saveWithRepeat` inside a
  bottom-sheet). Duplicated across ~5 sites and impossible for a non-UI caller
  (like an agent) to reuse without also reusing the widget.
- No seam for tests: DB access went straight to the on-disk singleton.
- No stable, UI-independent API that a future agent could target.

---

## 3. Problems intentionally NOT fixed (out of scope)

- **`DatabaseManager` was not rewritten or split.** It remains a large singleton
  with a shared static database handle. Per the constraints, its internals,
  schema, and semantics are untouched.
- **State management was not unified.** The app still mixes BLoC/Cubit,
  `ChangeNotifier`, and global providers. Only the code needed to remove direct
  `DatabaseManager` dependencies or to move business rules out of the UI was
  changed.
- **Models were not moved en masse.** Existing models stay in `lib/data/models`;
  no duplicate model classes or mapping layers were introduced.
- **No `features/` reorganization.** The minimal `domain/` + `data/repositories/`
  structure was chosen to limit churn.
- **Reminder/notification side effects were not extracted** from
  `create/update/deleteTimeInterval`; they remain inside the persistence path.

---

## 4. Target architecture — how repositories were chosen

Repositories model **domain capabilities**, not one-per-table:

- **`TaskRepository`, `TaskListRepository`, `CalendarRepository`,
  `NoteRepository`, `TimeIntervalRepository`** — per-entity CRUD + queries.
  Trash (soft-delete) and archive are exposed here as *capabilities of the
  entity* (`softDeleteTask`, `archiveTask`, `restoreTaskList`, …), not as
  separate objects.
- **`TrashRepository` and `ArchiveRepository`** — kept as their own boundaries
  because the "all trashed items" / "all archived items" views are genuine
  **cross-entity aggregates** spanning tasks, task lists, and calendar events,
  with type-dispatched restore/unarchive/moveToTrash. This earns a boundary.
- **`EventRepository`** — deliberately minimal (only `getEventsOfTaskList`),
  since that is the sole caller of the legacy `events` table. No speculative
  surface.

Business rules were moved into **domain services** so both the UI and a future
agent invoke identical logic:

- `TaskCompletionService` — toggle/set completion, measurable progress (Task).
- `TimeIntervalProgressService` — toggle completion, measurable progress
  (TimeInterval).
- `RecurrenceService` (+ `RepeatRule`) — expand a repeating interval into
  independent occurrences and persist them.

---

## 5. Files created

**Domain interfaces** (`lib/domain/repositories/`):

- `task_repository.dart`
- `task_list_repository.dart`
- `time_interval_repository.dart` (includes `rescheduleAllReminders()`)
- `calendar_repository.dart` (includes sync support: pending-sync, by-Google-id,
  mark-synced)
- `note_repository.dart`
- `trash_repository.dart`
- `archive_repository.dart`
- `event_repository.dart`

**Domain services** (`lib/domain/services/`):

- `task_completion_service.dart`
- `time_interval_progress_service.dart`
- `recurrence_service.dart`
- `repeat_rule.dart` (moved here from a widget folder)

**Data adapters** (`lib/data/repositories/`): thin 1:1 delegations to
`DatabaseManager`, each accepting an optional `DatabaseManager?` for tests:

- `sqlite_task_repository.dart`
- `sqlite_task_list_repository.dart`
- `sqlite_time_interval_repository.dart`
- `sqlite_calendar_repository.dart`
- `sqlite_note_repository.dart`
- `sqlite_trash_repository.dart`
- `sqlite_archive_repository.dart`
- `sqlite_event_repository.dart`

**Tests** (`test/`):

- `data/sqlite_task_repository_test.dart`
- `data/sqlite_task_list_repository_test.dart`
- `data/sqlite_calendar_repository_test.dart`
- `data/sqlite_note_repository_test.dart`
- `data/sqlite_trash_archive_repository_test.dart`
- `domain/task_completion_service_test.dart`
- `domain/time_interval_progress_service_test.dart`
- `domain/recurrence_service_test.dart`
- `domain/agent_readiness_proof_test.dart`

**Config / docs:**

- `dart_test.yaml` (`concurrency: 1`)
- `ARCHITECTURE_REFACTOR_REPORT.md` (this file); `README.md` architecture
  sections rewritten.

## 6. Files moved

- `repeat_rule.dart` — moved from `screen_tasks/.../component_widgets/` into
  `lib/domain/services/`. Its two importers were updated by hand (the move tool
  did not auto-update imports).

## 7. Files deleted

- No source files were deleted. Dead code was removed *in place* (e.g. an unused
  `_deleteDatabase()` in the tasks overview page, a dead counter widget test
  replaced by a smoke test).

## 8. Key modified files (behavior-preserving)

- `lib/app/app.dart` — added `MultiRepositoryProvider` for all repos/services;
  `AppBloc` now takes a `TimeIntervalRepository` (for `ToggleRemindersEnabled` →
  `rescheduleAllReminders`) instead of calling `DatabaseManager` directly.
- `lib/data/database/database_manager.dart` — **additive** test seam only:
  `@visibleForTesting resetForTesting({bool inMemory = true})`, and a
  `_schemaVersion` constant replacing the literal `11`. No production path
  changed. `resetForTesting` nulls the handle first, then best-effort closes the
  old one (test isolation).
- `page_tasks_overview.dart`, calendar views (`view_daily/weekly/monthly.dart`),
  `mapping.dart`, `home/data_controller.dart` (+ provider), sync services
  (`google_calendar_sync_service.dart`, `device_calendar_sync_service.dart`) —
  rewired from `DatabaseManager` to injected repositories/services.
- `main.dart` — trash purge now via `SqliteTrashRepository().purgeExpiredTrash`.

---

## 9. Public API changes

- **Added:** the domain repository interfaces and domain services listed above.
  These are the new public surface the UI (and a future agent) depend on.
- **Unchanged:** `DatabaseManager`'s public methods still exist and behave
  identically; the Sqlite adapters call them 1:1.
- **No breaking change** to any model, screen, or persisted format.

---

## 10. Database impact

**None.** Schema version stays at **11**. No migration, trigger, table, column,
backup format, or sync-token behavior was altered. The only DB-file change is the
`@visibleForTesting resetForTesting` seam, which opens an **in-memory** database
using the *same* `onCreate`/`onUpgrade`/version/`PRAGMA foreign_keys = ON` config
and is never invoked by production code.

---

## 11. Platform impact

**None to production behavior.** The refactor is pure structure/DI. One
platform-specific fact surfaced during testing (see Remaining risks): creating a
`TimeInterval` triggers `NotificationService`, which constructs an `AudioPlayer`
/ local-notifications plugin — a platform channel that is unavailable in a
headless VM test binding. This is unchanged from before; it was simply made
visible by the new repository-level tests.

---

## 12. Tests, analyze, and results

- **Test model:**
  - Domain-service tests use in-memory fakes of the repository interfaces
    (fast, DB-free).
  - Repository contract tests run the real `Sqlite*` adapters against an
    in-memory SQLite DB via `resetForTesting(inMemory: true)`.
  - `agent_readiness_proof_test.dart` drives a full lifecycle through domain
    abstractions only (see §13).
- **Running the suite:** `flutter test`. Because `DatabaseManager` is a
  process-wide singleton with a shared handle, `dart_test.yaml` pins
  `concurrency: 1` so DB test files run serially. Each DB test file also passes
  in isolation (e.g. `flutter test test/data/sqlite_task_repository_test.dart`).
- **Latest results:**
  - `flutter test` → **44 tests, all passing** (`+44: All tests passed!`).
  - `flutter analyze` → **0 errors.** Remaining items are pre-existing
    `info`/`warning` lints (e.g. `avoid_print`, `deprecated_member_use`), the
    bulk of which come from the vendored `packages/time_manager` package and are
    out of scope.
  - `flutter analyze test` → **No issues found.**

---

## 13. Agent-readiness verification

`test/domain/agent_readiness_proof_test.dart` constructs an `_AgentToolbox`
composed **only** of domain abstractions (no `DatabaseManager` field or import)
and runs, against a real in-memory database:

1. Full lifecycle: create project → add task → complete → archive → move to
   trash → restore, all through domain services/repositories.
2. Cross-instance consistency: a freshly constructed repository sees writes made
   through another instance.

This confirms the intended chain:

```
AI Tool → Domain Service / Repository → Data Repository (Sqlite* adapter) → DatabaseManager → SQLite
```

Because completion / progress / recurrence are domain services, an agent cannot
bypass those rules to write inconsistent state.

**Direct `DatabaseManager` references remaining outside `lib/data/` (all
acceptable, none from UI/Bloc/Controller):**

- `main.dart` — `setCurrentDeviceId` (startup config) and the desktop FFI setup.
- `screen_focus_timer/data/focus_repository.dart` — this file *is* a repository
  (the data layer for the focus feature).

No screen, widget, Bloc, or controller imports `DatabaseManager`.

---

## 14. Remaining risks

- **Headless `TimeInterval` writes need plugin mocks.** `createTimeInterval` /
  `updateTimeInterval` schedule reminders via `NotificationService`, whose
  `AudioPlayer` field initializer calls a platform channel that crashes under a
  pure-VM test binding. A headless agent (or a DB-level TimeInterval test) must
  provide a `TestWidgetsFlutterBinding` plus channel mocks, or route interval
  scheduling through a UI-bound context. The pure recurrence-expansion rule is
  covered headlessly via a fake repository. **No `TimeIntervalRepository`
  DB-level contract test was added** for this reason.
- **Shared singleton in tests.** DB test files share one static database handle,
  so the suite must run serially (`concurrency: 1`). Making `DatabaseManager`'s
  handle per-instance would touch ~60 call sites and was deliberately avoided.
- **Pre-existing lints remain** in app code and in the vendored
  `packages/time_manager`. These predate the refactor and were not in scope.
- **`FocusRepository` still references `DatabaseManager` directly** — acceptable
  because it is itself a repository, but it predates and does not follow the new
  `domain/` interface pattern; it could be aligned later if desired.

---

## 15. Ready for AI?

**YES — the domain boundary is in place and verified.**

A future agent can perform task/list/calendar/note/trash/archive workflows
through the domain API today, proven by the agent-readiness test. Before wiring
an actual agent, address one item: **time-interval scheduling** must run with a
Flutter binding and mocked notification/audio channels (or have its reminder
side effect made optional/injectable) so an agent can create scheduled intervals
headlessly. Everything else — completion, measurable progress, recurrence
expansion, and full CRUD with trash/archive — is reachable and rule-safe without
touching `DatabaseManager` or SQL.

Per the constraints, **no AI/Ollama/llama.cpp/Rust dependencies were installed,
and this report is the stopping point before any AI implementation.**
