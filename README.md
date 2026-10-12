# My Time Manager

A cross-platform time-management application built with **Flutter**: manage tasks, calendar events, notes, and a Pomodoro focus timer, plus supporting features such as trash, archive, backup/restore, and calendar synchronization.

- **Supported platforms:** Android, iOS, Windows, Linux, macOS, Web (some features are platform-dependent — see [Platform notes](#platform-notes)).
- **Version:** `1.5.3+23` (see `pubspec.yaml`).
- **Storage:** local-first with SQLite; optional cloud sync via Firebase.

---

## Table of contents

- [Screenshots](#screenshots)
- [Features](#features)
- [User guide](#user-guide)
- [Getting started (for developers)](#getting-started-for-developers)
- [Project architecture](#project-architecture)
  - [Layer overview](#layer-overview)
  - [Directory structure](#directory-structure)
  - [Data layer](#data-layer)
  - [Data models](#data-models)
  - [Domain layer](#domain-layer)
  - [State management](#state-management)
  - [Startup and navigation](#startup-and-navigation)
  - [Local packages](#local-packages)
  - [Agent-readiness](#agent-readiness)
  - [Testing](#testing)
- [Database schema](#database-schema)
- [Calendar sync flow](#calendar-sync-flow)
- [Platform notes](#platform-notes)
- [Notable dependency constraints](#notable-dependency-constraints)

---


## Features

- **Task management:** create/edit tasks that belong to task lists. A single task can be:
  - a **plain task**,
  - a **measurable task** (`isMeasurable`: at-least / at-most / about target, unit, progress done),
  - a task **with subtasks** — each subtask can itself be measurable and be scheduled independently.
- **Time planning (time intervals):** attach time ranges (start/end date and time) to a task or subtask; supports notification reminders.
- **Calendar:** a `CalendarEvent` model compatible with Google Calendar (supports lists, soft-delete, archive, and sync fields).
- **Notes:** block/rich-text editor based on `appflowy_editor`.
- **Focus timer (Pomodoro):** a globally running focus timer with a floating (PiP) window, alarm sound, and system notifications.
- **Trash:** soft-delete with automatic purge after a configurable retention period (default 30 days).
- **Archive:** hide tasks/lists from the main screens without deleting them.
- **Backup & restore:** export/import data (JSON/CSV/text) via `backup_service`/`import_service`; every record carries a `deviceId` to help resolve conflicts on import.
- **Calendar sync:** with the device calendar and with Google Calendar.
- **Authentication (optional):** Firebase Auth (email/password, Google Sign-In). The app still runs if Firebase is not configured.
- **UI customization:** Material 2/3, light/dark/system, color from a seed or from an image, optional bottom bar, and **13 languages** (cs, de, en, es, fr, it, ja, ko, no, ru, sv, vi, zh).

---

## User guide

> This section describes end-user usage. The concrete screen layout is driven by `Home` (bottom navigation bar or side rail, depending on settings).

**Tasks & lists**
1. Open the **Tasks** screen to view lists and tasks (Overview / Timeline).
2. Create a new task. To track it quantitatively, enable the **measurable target** (enter a target and a unit). To break it down, add **subtasks**.
3. On the task edit page, use the **"Schedule"** tile to set time intervals; you can add notification **reminders**.

**Calendar**
- The **Calendar** screen shows events. An event can belong to a list and can be synced with the device calendar and Google Calendar (once configured / signed in).

**Notes**
- The **Notes** screen lets you compose rich-text notes. Notes can be attached to tasks/time intervals.

**Focus timer (Pomodoro)**
- Pick a task (or none) and start a focus session. Enable the **run-in-background** option so the timer keeps running when you leave the screen; a floating window shows progress.

**Trash & archive**
- Deleted items go to **Trash** and can be restored; the system auto-purges them after the configured retention period.
- Use **Archive** to hide items from the main screens while keeping their data.

**Backup / restore**
- Go to **Settings** to export data (JSON/CSV/text) or import from a file. Records carry a `deviceId` to help merge data imported from another device.

**Appearance & language**
- In **Settings**: switch light/dark, Material 2/3, choose colors (seed or image based), task card style, which buttons appear in the AppBar, and the language.

---

## Getting started (for developers)

**Requirements**
- Flutter SDK compatible with Dart `>=3.0.1 <4.0.0`.
- On Windows desktop: a C++/CMake build toolchain (SQLite runs through FFI; the DLL is bundled by `sqlite3_flutter_libs`).

**Install & run**
```bash
flutter pub get
flutter run                 # choose an available device/platform
```

**Static analysis**
```bash
flutter analyze
```
> Temporary backup folders are excluded from analysis in `analysis_options.yaml`.

**Firebase (optional)**
- If you have not run `flutterfire configure`, `firebase_options.dart` is a placeholder and the app runs in **no-auth mode** (sign-in is skipped, local features still work). Once configured, sign-in and Firestore sync become available.

**Code generation (if you change models that use json_serializable)**
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Project architecture

### Layer overview

The app follows a **local-first** model with a **domain-driven boundary** between the UI and the database:

```
UI (screens / component_widgets / view)
        │  depends only on domain abstractions
State management (BLoC / Cubit / ChangeNotifier)
        │
Domain layer  (lib/domain)
   ├─ Repository interfaces   (TaskRepository, TaskListRepository,
   │                           TimeIntervalRepository, CalendarRepository,
   │                           NoteRepository, TrashRepository,
   │                           ArchiveRepository, EventRepository)
   └─ Domain services         (TaskCompletionService, TimeIntervalProgressService,
                               RecurrenceService  — the business rules)
        │  implemented by
Data layer  (lib/data/repositories)
   └─ Sqlite* adapters        (thin, 1:1 delegation to DatabaseManager)
        │
DatabaseManager  (lib/data/database)  — schema, CRUD, migration, trash/archive,
        │                                reminders, export/import table list
Persistence (SQLite via sqflite / sqflite_common_ffi)  +  Optional cloud (Firebase Auth / Firestore)
```

- **UI / Bloc / Controller never touch `DatabaseManager` or SQL directly.** They depend on the domain repository interfaces and domain services, which are provided app-wide via `MultiRepositoryProvider` in `app/app.dart`. The only remaining non-data references to `DatabaseManager` are `main.dart` (`setCurrentDeviceId`, a startup config call) and `FocusRepository` (which *is* a repository).
- **Business rules live in domain services, not in widgets.** Task/interval completion, measurable progress, and recurrence expansion were moved out of the UI so that both the UI and — in the future — an AI agent invoke the exact same rules. See [Agent-readiness](#agent-readiness).
- **Cloud is optional**: if Firebase is not ready, the sync layers use **NoOp** implementations so the app runs fully offline.

### Directory structure

```
lib/
├── main.dart                  # Entry point: init notifications, deviceId, SQLite FFI, purge trash, Firebase
├── firebase_options.dart      # Firebase configuration (placeholder until configured)
├── app/
│   ├── app.dart               # Root App widget: MaterialApp, theme, locale, AppBloc, global providers
│   └── app_localizations.dart # Translations (13 languages)
├── auth/                       # Authentication (Firebase): bloc/ data/ view/, auth_config.dart
├── domain/                     # Domain boundary (no Flutter/SQLite imports in interfaces)
│   ├── repositories/          # Repository interfaces (domain capabilities, not tables)
│   └── services/              # Business rules: completion, progress, recurrence + repeat_rule
├── data/
│   ├── database/              # database_manager.dart (schema, CRUD, migration), sample_data.dart
│   ├── repositories/          # Sqlite* adapters implementing the domain interfaces
│   ├── models/                # Data models (see below)
│   ├── backup/                # backup_service.dart (export), import_service.dart (import)
│   ├── sync/                  # calendar_sync_manager + device/google calendar sync services
│   ├── device_calendar/       # device_calendar_service.dart (read/write the system calendar)
│   └── device_id_provider.dart# Device identity for export/import
├── home/                       # Home shell, data_controller (ChangeNotifier), timetable
├── screen_tasks/               # Task screens (overview, timeline) + component_widgets
├── screen_calendar/            # Calendar screens
├── screen_notes/               # Notes (appflowy_editor)
├── screen_focus_timer/         # Pomodoro: bloc/ data/ view/ + timer_bloc.dart
├── screen_archive/             # Archive
├── screen_trash/               # Trash
├── screen_settings/            # Settings
├── screen_about_us/            # About
├── screen_material_design/     # Material Design showcase
├── ads_mob/                    # AdMob integration (currently disabled in main.dart)
├── shared/                     # appflowy_description.dart (helper for the description editor)
└── utils/                      # constants.dart, utils.dart, widget_coming_soon.dart

packages/
├── time_manager/               # Local plugin (rrule, timezone) — time/recurrence logic, has native code
└── calendar_widgets/           # Local package — customized calendar widgets (table calendar)
```

Repeated naming convention across features: `bloc/` (state), `data/` (repository/service), `view/` (UI), and `component_widgets/` (reusable child widgets).

### Domain layer

`lib/domain` is the contract the rest of the app depends on. It contains **no** direct SQLite or `DatabaseManager` references.

- **Repository interfaces** (`lib/domain/repositories/`) model *domain capabilities*, not database tables. Trash and archive, for example, are exposed as capabilities of the entity repositories (`softDeleteTask`, `archiveTask`, …), plus two **cross-entity aggregate** repositories — `TrashRepository` and `ArchiveRepository` — because the "all trashed / all archived items" view genuinely spans tasks, task lists, and calendar events. `EventRepository` is intentionally minimal (only `getEventsOfTaskList`) since that is the sole caller of the legacy `events` table.
- **Domain services** (`lib/domain/services/`) hold business rules that used to be inline in widgets:
  - `TaskCompletionService` — toggle/set completion, measurable progress for a `Task`.
  - `TimeIntervalProgressService` — toggle completion / measurable progress for a `TimeInterval`.
  - `RecurrenceService` (+ `repeat_rule.dart`) — expands a repeating interval into independent occurrences and persists them.

### Data layer

- **`DatabaseManager`** (`lib/data/database/database_manager.dart`): a singleton that opens SQLite, defines the schema, provides CRUD for every table, and manages **version-based migration**. It also owns soft-delete/trash, archive, reminders, and the list of tables used for export/import. Its implementation, schema, migrations, triggers, backup format, and sync semantics were **left unchanged** by the domain refactor.
- **Sqlite\* repositories** (`lib/data/repositories/`): thin adapters that implement the domain interfaces by delegating **1:1** to `DatabaseManager` (e.g. `SqliteTaskRepository`, `SqliteCalendarRepository`, `SqliteTrashRepository`). Each takes an optional `DatabaseManager?` (defaulting to the singleton) so tests can drive them against an in-memory database. Side effects such as reminder scheduling on `createTimeInterval` are preserved inside these adapters.
- **Services:**
  - `backup/backup_service.dart` — exports data (JSON/CSV/text). CSV uses `CsvEncoder` from the `csv` 8.x package.
  - `backup/import_service.dart` — imports data from a file.
  - `sync/` — `calendar_sync_manager.dart` orchestrates; `device_calendar_sync_service.dart` and `google_calendar_sync_service.dart` are the two sync backends.
  - `device_calendar/device_calendar_service.dart` — reads/writes the system calendar (mobile only).
- **`device_id_provider.dart`** — generates/loads `deviceId`; every record written on this machine carries the `deviceId` to help resolve conflicts on import.

### Data models

In `lib/data/models/`:

- **`model_task.dart` — the unified `Task` model (core).** The app previously split tasks into 3 types (`Task`, `MeasurableTask`, `TaskWithSubtasks`); they are now merged into **one** `Task`:
  - `isMeasurable = true` ⇒ the task has a measurement target (`targetType`/`targetAtLeast`/`targetAtMost`/`unit`/`howMuchHasBeenDone`).
  - a non-empty `subtasks` list ⇒ the task has subtasks (`hasSubtasks` is a convenience getter).
  - `Subtask` has `id`, `title`, `isCompleted`, and can also be measurable.
  - `TargetType`: `atLeast`, `atMost`, `about`.
- **`model_measurable_task.dart` / `model_task_with_subtasks.dart`** — now just **re-export files** for backward compatibility, exporting `Task`/`Subtask`/`TargetType` from `model_task.dart`.
- **`model_list.dart`** — `TaskList` (a list that holds tasks/events).
- **`model_time_interval.dart`** — `TimeInterval` (a planned time range), linked to a task via `taskId` and to a subtask via `subtaskId`.
- **`model_calendar_event.dart`** — `CalendarEvent`, compatible with Google Calendar.
- **`model_note.dart`** — `Note`.
- **`models.dart`** — barrel export.

### State management

A mix of mechanisms, chosen by scope:

- **BLoC / Cubit (`bloc`, `flutter_bloc`):**
  - `AppBloc` (in `app/app.dart`) — app-wide UI configuration (theme, color, language, settings), **persisted through `SharedPreferences`**.
  - `AuthBloc` (`auth/bloc`) — sign-in state.
  - `PomodoroBloc` — provided **globally** (a single instance that lives for the app's whole lifetime) so the timer keeps running across screens.
- **`ChangeNotifier`:** `home/data_controller.dart` (`DataController`) manages the calendar/time-interval display data; it is constructor-injected with a `TimeIntervalRepository`.
- **Repository/Service:** `FocusRepository` (local-first) with a Firestore sync layer enabled when Firebase is ready, otherwise a `NoOpFocusSyncService`.
- **Dependency injection:** domain repositories and services are provided once, app-wide, by a `MultiRepositoryProvider` in `app/app.dart`. Blocs and controllers receive them via constructor injection (e.g. `AppBloc` takes a `TimeIntervalRepository` for reminder rescheduling), and widgets read them with `context.read<...>()`.

### Startup and navigation

Sequence in `main.dart`:
1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Initialize `NotificationService` (loads timezone) and request notification permissions.
3. Initialize `DeviceIdProvider` and set the `deviceId` on `DatabaseManager`.
4. On desktop: `sqfliteFfiInit()` + set `databaseFactory = databaseFactoryFfi`.
5. Purge expired trash (`purgeExpiredTrash`; retention days read from `SharedPreferences`).
6. Initialize Firebase inside a `try/catch`; if it fails or is unconfigured, `firebaseReady = false`.
7. `runApp(App(...))`.

`App` (in `app/app.dart`) builds `MaterialApp` with theme/locale from `AppBloc`, provides `FocusRepository` + `PomodoroBloc` globally, and:
- If Firebase is ready ⇒ provides `AuthRepository`/`AuthBloc` and wraps `Home` in **`AuthGate`** (redirects based on sign-in state). There is an `AuthConfig.bypassAuth` flag to go straight to `Home` during testing.
- Otherwise ⇒ goes straight to `Home` (no-auth mode).
- Every screen is wrapped in `PomodoroFloatingOverlay` (the floating Pomodoro window).

> **AdMob** (`ads_mob/`, `google_mobile_ads`) is currently **disabled** in `main.dart`; re-enable it following the comment at the end of `main()` once you have a valid App ID.

### Local packages

Located in `packages/`, referenced by `path` in `pubspec.yaml` so the project is self-contained:

- **`time_manager`** — an internal plugin (declares native code for Android/iOS/Windows/…): handles time and recurrence logic (`rrule`, `timezone`).
- **`calendar_widgets`** — a calendar-widget package (a table-calendar variant) used by the calendar screens.

### Agent-readiness

The domain boundary was designed so a future AI agent can drive the app the same way the UI does — **through domain services and repositories, never by touching `DatabaseManager` or SQL**. The intended call chain is:

```
AI Tool  ->  Domain Service / Repository  ->  Data Repository (Sqlite* adapter)  ->  DatabaseManager  ->  SQLite
```

Because business rules (completion, measurable progress, recurrence) live in domain services, an agent that calls those services cannot bypass them to write inconsistent state directly to the database.

This is verified by `test/domain/agent_readiness_proof_test.dart`, which builds a small `_AgentToolbox` from domain abstractions only and runs a full lifecycle (create project → add task → complete → archive → move to trash → restore) against a real in-memory SQLite database. It also confirms that repositories constructed independently still read/write the same store.

> **Known platform coupling:** `TimeInterval` create/update schedules reminders via `NotificationService`, which instantiates plugin channels (audio / local notifications). That path needs a Flutter binding and channel mocks, so an agent running headless must either provide those or route interval scheduling through a UI-bound context. The pure recurrence-expansion rule itself is covered headlessly in `recurrence_service_test.dart`.

### Testing

- Domain-service tests (`test/domain/`) use in-memory fakes of the repository interfaces — fast and DB-free.
- Repository contract tests (`test/data/`) run the real `Sqlite*` adapters against an in-memory SQLite database via `DatabaseManager.resetForTesting(inMemory: true)` (a `@visibleForTesting` seam that does not change any production path). They cover task, task-list (including the timestamp-matched cascade restore/unarchive of child tasks), calendar, note, and the cross-entity trash/archive aggregates.
- Because `DatabaseManager` is a process-wide singleton with a shared handle, the full suite is pinned to serial execution in `dart_test.yaml` (`concurrency: 1`). Run the whole suite with `flutter test`; individual DB files also pass in isolation (e.g. `flutter test test/data/sqlite_task_repository_test.dart`).

---

## Database schema

- Current schema version: **11** (see `_initDatabase`/`_onCreate`/`_onUpgrade`).
- SQLite runs through **FFI** on desktop (`sqflite_common_ffi`). Foreign keys are enabled (`PRAGMA foreign_keys = ON`).
- Nested objects (subtasks, attendees, reminders, recurrence, etc.) are stored as **JSON strings** in `TEXT` columns.

### Tables

**`tasklists`** — task/event lists.

| Column | Type | Notes |
| --- | --- | --- |
| id | TEXT | Primary key |
| title | TEXT | |
| description | TEXT | Plain-text description |
| descriptionDoc | TEXT | appflowy_editor JSON (rich text) |
| color | INTEGER | ARGB value |
| dataFiles | TEXT | JSON list of attachment paths |
| updateTimeStamp | TEXT | |
| isDeleted | INTEGER | Soft-delete, default 0 |
| deletedAt | TEXT | |
| isArchived | INTEGER | Default 0 |
| archivedAt | TEXT | |
| deviceId | TEXT | Source device |

**`tasks`** — the unified task model.

| Column | Type | Notes |
| --- | --- | --- |
| id | TEXT | Primary key |
| taskListId | TEXT | FK → `tasklists(id)` ON DELETE CASCADE |
| isCompleted | INTEGER | NOT NULL |
| isImportant | INTEGER | NOT NULL |
| title | TEXT | |
| description | TEXT | |
| descriptionDoc | TEXT | Rich-text JSON |
| location | TEXT | |
| color | INTEGER | |
| tags | TEXT | JSON list |
| dataFiles | TEXT | JSON list |
| noteIds | TEXT | JSON list of attached note ids |
| isMeasurable | INTEGER | NOT NULL, default 0 |
| targetAtLeast | REAL | |
| targetAtMost | REAL | |
| targetType | INTEGER | `TargetType` index |
| unit | TEXT | |
| howMuchHasBeenDone | REAL | |
| subtasks | TEXT | JSON list of `Subtask` |
| updateTimeStamp | TEXT | |
| isDeleted / deletedAt | INTEGER / TEXT | Soft-delete |
| isArchived / archivedAt | INTEGER / TEXT | Archive |
| deviceId | TEXT | |

**`timeintervals`** — planned time ranges for a task or subtask.

| Column | Type | Notes |
| --- | --- | --- |
| id | TEXT | Primary key |
| isCompleted | INTEGER | NOT NULL |
| isImportant | INTEGER | NOT NULL |
| taskId | TEXT | FK → `tasks(id)` ON DELETE CASCADE |
| subtaskId | TEXT | Points to a subtask (subtasks live inside `tasks.subtasks`) |
| location | TEXT | |
| color | INTEGER | |
| title | TEXT | |
| description | TEXT | |
| descriptionDoc | TEXT | Rich-text JSON |
| startDate / endDate | TEXT | |
| startTime / endTime | INTEGER | Minutes-of-day (nullable) |
| isStartDateUndefined | INTEGER | NOT NULL |
| isEndDateUndefined | INTEGER | NOT NULL |
| isStartTimeUndefined | INTEGER | NOT NULL |
| isEndTimeUndefined | INTEGER | NOT NULL |
| targetAtLeast / targetAtMost | REAL | |
| targetType | INTEGER | |
| unit | TEXT | |
| howMuchHasBeenDone | REAL | |
| subtasks | TEXT | JSON list |
| dataFiles | TEXT | JSON list |
| noteIds | TEXT | JSON list |
| updateTimeStamp | TEXT | |
| timeZone | TEXT | |
| deviceId | TEXT | |
| reminders | TEXT | JSON list of minutes-before for notifications |

**`calendar_events`** — Google-Calendar-compatible events (added in v11).

| Column | Type | Notes |
| --- | --- | --- |
| id | TEXT | Primary key |
| taskListId | TEXT | FK → `tasklists(id)` ON DELETE CASCADE |
| title / description / location | TEXT | |
| color | INTEGER | |
| colorId | TEXT | Google color id |
| startDateTime / endDateTime | TEXT | |
| isAllDay | INTEGER | NOT NULL, default 0 |
| recurrence | TEXT | JSON (RRULE lines) |
| recurringEventId | TEXT | |
| originalStartTime | TEXT | |
| attendees | TEXT | JSON list |
| organizerEmail / organizerDisplayName / creatorEmail | TEXT | |
| status / visibility / transparency | TEXT | |
| guestsCanInviteOthers | INTEGER | NOT NULL, default 1 |
| guestsCanModify | INTEGER | NOT NULL, default 0 |
| guestsCanSeeOtherGuests | INTEGER | NOT NULL, default 1 |
| reminders | TEXT | JSON list |
| conferenceUrl | TEXT | |
| dataFiles / noteIds | TEXT | JSON list |
| iCalUID | TEXT | |
| googleEventId | TEXT | Remote event id (set once synced) |
| calendarId | TEXT | |
| etag | TEXT | For optimistic concurrency (If-Match) |
| sequence | INTEGER | NOT NULL, default 0 |
| created / updated | TEXT | |
| syncStatus | TEXT | `EventSyncStatus` (localOnly / pendingUpdate / pendingDelete / synced) |
| isDeleted / deletedAt | INTEGER / TEXT | Soft-delete |
| isArchived / archivedAt | INTEGER / TEXT | Archive |
| deviceId | TEXT | |

**`events`** — a simpler legacy event table (kept as-is).

| Column | Type | Notes |
| --- | --- | --- |
| id | TEXT | Primary key |
| taskListId | TEXT | FK → `tasklists(id)` ON DELETE CASCADE |
| title / description / location | TEXT | |
| color | INTEGER | |
| startTimeStamp / endTimeStamp | INTEGER | |
| tags / dataFiles | TEXT | JSON list |
| updateTimeStamp | TEXT | |
| deviceId | TEXT | |

**`focus_sessions`** — recorded Pomodoro sessions (no FK: `taskId` may reference different sources or be null; `taskTitle` is stored so stats survive task deletion).

| Column | Type | Notes |
| --- | --- | --- |
| id | TEXT | Primary key |
| taskType | INTEGER | NOT NULL |
| taskId | TEXT | |
| taskTitle | TEXT | Snapshot of the task title |
| startTime / endTime | TEXT | NOT NULL |
| focusDurationSeconds | INTEGER | NOT NULL |
| completed | INTEGER | NOT NULL |
| synced | INTEGER | NOT NULL (Firestore sync flag) |
| deviceId | TEXT | |

**`notes`** — rich-text notes.

| Column | Type | Notes |
| --- | --- | --- |
| id | TEXT | Primary key |
| title | TEXT | |
| contentJson | TEXT | appflowy_editor document JSON |
| createdAt / updatedAt | TEXT | |
| deviceId | TEXT | |

### Triggers

Created by `_createTaskTriggers` (used both on create and on the v9 upgrade):
- `update_timeintervals_of_task_title_color_isImportant` — `AFTER UPDATE OF title, color, isImportant ON tasks`: propagates title/color/importance changes down to the task's time intervals.
- `delete_timeintervals_of_task` — `AFTER DELETE ON tasks`: removes the task's time intervals.

### Migration milestones (`_onUpgrade`)

`_onUpgrade` applies steps sequentially (`if (oldVersion < N)`); each step only touches tables that **already exist at that version**.

| Version | Change |
| --- | --- |
| v2 | Add `focus_sessions` table |
| v3 | Add soft-delete columns (`isDeleted`/`deletedAt`) |
| v4 | Add `deviceId` column |
| v5 | Add `reminders` to `timeintervals` |
| v6 | Add `notes` table |
| v7 | Add `descriptionDoc` column |
| v8 | Add `noteIds` column |
| **v9** | Merge the 3 task types into the unified `Task`; rebuild `tasks`/`timeintervals` and triggers |
| v10 | Add archive columns (`isArchived`/`archivedAt`) |
| **v11** | Add the `calendar_events` table |

> Tables introduced in a later version (e.g. `calendar_events` in v11) are **not** altered by earlier steps — they are created with all their columns already present.

---

## Calendar sync flow

`CalendarSyncManager` (in `data/sync/`) is the high-level orchestrator. It connects `AuthRepository.calendarAccessToken` (a real OAuth access token) to `GoogleCalendarSyncService`, and stores sync configuration in `SharedPreferences`: enabled flag, selected `calendarId` (default `'primary'`), a per-calendar `syncToken` (for incremental sync), and a `taskListId` to attach pulled events to.

The UI only calls `syncNow()`. A two-way sync **pushes local changes first, then pulls remote changes**:

```
                         CalendarSyncManager.syncNow()
                                     │
                 read config from SharedPreferences
              (calendarId, taskListId, saved syncToken)
                                     │
                    GoogleCalendarSyncService.syncTwoWay()
                                     │
          ┌──────────────────────────┴──────────────────────────┐
          │  1) PUSH  (pushPending)                              │
          │     for each local event by syncStatus:              │
          │       • localOnly      → POST create (remote)        │
          │       • pendingUpdate  → PATCH update (If-Match etag) │
          │                          or POST create if no id      │
          │       • pendingDelete  → DELETE remote                │
          │       • synced         → skip                         │
          └──────────────────────────┬──────────────────────────┘
                                     │
          ┌──────────────────────────┴──────────────────────────┐
          │  2) PULL  (pull)                                     │
          │     • incremental if a syncToken exists              │
          │     • otherwise full sync within a ±1 year window     │
          │     • upsert events locally (mark syncStatus=synced) │
          │     • attach new events to taskListId (if set)       │
          │     • follow nextPageToken across pages              │
          └──────────────────────────┬──────────────────────────┘
                                     │
              save nextSyncToken for the next incremental sync
                                     │
                 return CalendarSyncOutcome(upserted, deleted)
```

Key points:
- **Optimistic concurrency:** updates send `If-Match: <etag>` so the server rejects the write if the event changed remotely.
- **Sync-token expiry:** if Google returns HTTP `410` (token expired), the saved token is cleared so the next run performs a full sync.
- **Error handling:** all errors are caught and reported through `CalendarSyncOutcome(success, upserted, deleted, error)` — a sync failure never crashes the app.
- **Device calendar:** `device_calendar_sync_service.dart` provides a separate backend for the system calendar (mobile only).

---

## Platform notes

- **Desktop (Windows/Linux/macOS):** SQLite runs through FFI. `sqlite3_flutter_libs` is **pinned to 0.5.42** so the `sqlite3` DLL is bundled via the classic CMake scripts (the `0.6.0+eol` release is an empty stub).
- **Windows & Google Sign-In:** there is no native flow; Google sign-in uses a manual OAuth flow via `http` (exchanging the authorization code for a token).
- **Device calendar:** supported only on Android/iOS; on desktop `DeviceCalendarService` returns empty results.
- **Notifications/sound:** system notifications are mainly for mobile; the alarm sound (`assets/sounds/alarm.mp3`) is mainly for desktop (the app still runs if the file is missing).

---

## Notable dependency constraints

Documented in detail in `pubspec.yaml`; the tricky points, summarized:

- **`google_sign_in: ^6.2.1`** — kept on the 6.x line because 7.x fully rewrote the API; `firebase_auth` does not depend on `google_sign_in`.
- **`csv: ^8.0.0`** — the new API uses `CsvEncoder` (`ListToCsvConverter` was removed).
- **`font_awesome_flutter: ^11.0.0`** — 10.x breaks because `IconData` is now `final` in newer Flutter.
- **`timezone: ^0.9.0`** — required by the local `time_manager` plugin and for scheduling notifications.
- **`flutter_timezone: ^5.0.0`** — returns `TimezoneInfo`; use `.identifier` to get the IANA name.
- **`appflowy_editor`** — uses the git `main` branch (to avoid an `intl` conflict with `flutter_localizations`).
- **`dependency_overrides`**: `file_picker: ^10.3.10`, `device_info_plus: ^12.3.0` (required by the `appflowy_editor` main branch).
