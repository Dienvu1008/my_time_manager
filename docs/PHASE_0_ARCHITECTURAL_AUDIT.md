# Phase 0 — Architectural Audit

**Goal of this phase:** understand the existing architecture and decide *where* the
AI layer will attach — **without implementing any AI code**. No dependencies were
added. This is a findings report only.

**Method:** inspected `lib/` (data, domain, screens, home, app), `pubspec.yaml`,
the database layer, and the task / calendar / time-interval / focus / note models
and their access paths.

---

## A. Current architecture

```
UI (screens: screen_tasks, screen_calendar, screen_focus_timer, screen_notes, home, ...)
        │  context.read<...>()  /  constructor injection
State management
   ├─ BLoC/Cubit: AppBloc, AuthBloc, PomodoroBloc, TaskListsHolderBloc
   └─ ChangeNotifier: DataController (home) — calendar/time-interval display data
        │
Domain layer  (lib/domain)   ← added by the earlier refactor
   ├─ repositories/  (8 interfaces)
   └─ services/      (TaskCompletionService, TimeIntervalProgressService, RecurrenceService, RepeatRule)
        │  implemented by
Data layer  (lib/data/repositories)  — Sqlite* adapters, 1:1 delegation
        │
DatabaseManager  (lib/data/database/database_manager.dart)  — singleton, schema v11
        │
SQLite (sqflite / sqflite_common_ffi)      +   Optional cloud (Firebase Auth / Firestore)
```

**UI layer.** Feature-first folders (`screen_tasks`, `screen_calendar`,
`screen_focus_timer`, `screen_notes`, `screen_archive`, `screen_trash`,
`screen_settings`, `home`). Convention per feature: `bloc/`, `data/`, `view/`,
`component_widgets/`.

**State management.** Mixed by scope: `AppBloc` (theme/locale/settings, persisted
via SharedPreferences), `AuthBloc` (Firebase sign-in), `PomodoroBloc` (global,
lives for the app lifetime), `TaskListsHolderBloc`, and `DataController`
(`ChangeNotifier`) for calendar/time-interval display.

**Domain/data access.** Dependency injection is centralized in a
`MultiRepositoryProvider` in `lib/app/app.dart`. Provided app-wide today:
`TaskRepository`, `TaskListRepository`, `TaskCompletionService`,
`TimeIntervalRepository`, `RecurrenceService`, `TimeIntervalProgressService`,
`CalendarRepository`, `NoteRepository`, `TrashRepository`, `ArchiveRepository`,
`EventRepository`, and `FocusRepository`. Widgets/blocs consume these; **no
UI/Bloc/Controller calls `DatabaseManager` directly** (verified in the prior
refactor).

**Database.** `DatabaseManager` singleton: schema v11, version-based migration,
soft-delete/trash, archive, reminders, export/import table list, FFI on desktop,
`PRAGMA foreign_keys = ON`. Nested objects stored as JSON in TEXT columns.

**Synchronization.** `CalendarSyncManager` orchestrates Google/device calendar
sync through `CalendarRepository` (push pending, then pull). Focus sessions sync
to Firestore via `FocusRepository` + a sync service (`NoOp` when Firebase is off).
Both are local-first.

**Platform-specific code.** Desktop uses `sqflite_common_ffi`. Notifications:
`flutter_local_notifications` on mobile, `audioplayers` sound on desktop.
`google_sign_in` (mobile) vs manual OAcode flow with `http` (Windows). Two local
packages under `packages/`: `time_manager` (native code, rrule/timezone) and
`calendar_widgets`.

**Relevant dependency note:** `http: ^1.2.0` is already present (reusable by the
future Ollama HTTP provider). No AI/inference dependency exists.

---

## B. Existing domain capabilities (ready for the Agent)

All are reachable **through the domain layer today**, no new code required:

| Agent need | Available API (domain) |
| --- | --- |
| read tasks | `TaskRepository.getTasks / getTask / getTasksOfTaskList / getTasksWithoutTaskList` |
| create tasks | `TaskRepository.createTask` |
| update tasks | `TaskRepository.updateTask / moveTask` |
| complete tasks | `TaskCompletionService.toggleCompleted / setCompleted / updateMeasurableProgress` |
| read calendar events | `CalendarRepository.getCalendarEvents / getCalendarEvent / getCalendarEventsOfTaskList / getCalendarEventsWithoutTaskList` |
| create calendar events | `CalendarRepository.createCalendarEvent` (also `updateCalendarEvent / moveCalendarEvent`) |
| read time intervals | `TimeIntervalRepository.getTimeIntervals / getTimeInterval / getTimeIntervalsOfTask / getAllTimeIntervalsOfTask / getTimeIntervalsOfSubtask` |
| create time intervals | `TimeIntervalRepository.createTimeInterval` (recurring: `RecurrenceService.saveWithRepeat`); update via `TimeIntervalProgressService` / `updateTimeInterval` |
| read focus sessions | `FocusRepository.allSessions / sessionsBetween` |
| read notes | `NoteRepository.getNotes / getNote` (create/update/delete also present) |
| trash / archive | entity repos (`softDeleteTask`, `archiveTask`, …) + aggregate `TrashRepository` / `ArchiveRepository` |

**Model facts that shape the tools:**

- **`Task`** carries `title`, `isCompleted`, `isImportant` (priority-ish),
  `isMeasurable` + target fields, `subtasks`, `tags`, `noteIds`, `taskListId`.
  It has **no `deadline`/`dueDate` and no time-estimate field.**
- **`TimeInterval`** is the schedulable unit: `startDate/startTime/endDate/endTime`,
  `reminderMinutesBefore`, measurable target, subtasks; linked to a task via
  `taskId` (+ optional `subtaskId`). **Deadlines/estimates for planning must be
  expressed via TimeIntervals, not Task fields.**
- **`FocusSession`** has `startTime`, `endTime`, `focusDurationSeconds`
  (`focusMinutes`), `completed`, `taskId`, `taskTitle` (denormalized). Enough raw
  data to compute focus statistics — but **no aggregation exists yet.**

---

## C. Missing domain APIs (smallest additions proposed — not implemented)

1. **Focus statistics (read-only aggregation).** `FocusRepository` returns only
   raw sessions. The Agent's `get_focus_statistics` / `get_focus_summary` needs a
   deterministic aggregate (total focus minutes, session count, per-day/-task
   breakdown, completion rate) over a date range. Proposed: a small
   `FocusStatisticsService` in the analytics area that consumes
   `FocusRepository.sessionsBetween` — **no SQL, no new table.**

2. **`FocusRepository` is not a domain interface.** It is a concrete class in
   `screen_focus_timer/data/` that imports `DatabaseManager` directly. To keep the
   Agent provider/data-agnostic like the other repos, propose extracting a
   `FocusRepository` **interface** into `lib/domain/repositories/` with the current
   class as its Sqlite implementation. Low-risk, additive.

3. **Analytics/planning metrics do not exist.** The Roadmap's Phase 11 metrics
   (PlanningAccuracy, ExecutionRate, EstimationBias, RescheduleRate,
   DeadlineMissRate, WorkloadScore) have **no supporting code**. Because `Task`
   lacks estimate/deadline fields, some of these require deriving estimate =
   planned interval duration and actual = focus time or completion timestamps.
   This is a genuine design item for Phase 11, flagged now.

4. **Note query is coarse.** `NoteRepository.getNotes()` returns all notes; there
   is no search/filter. A safe read-only `searchNotes(query)` (in-memory filter
   over titles/updatedAt) may be worth adding when notes tools are built (Phase 3),
   but only if needed — no speculative surface now.

5. **Time-interval write side effect (platform coupling).** `createTimeInterval` /
   `updateTimeInterval` invoke `NotificationService`, whose `AudioPlayer` field
   initializer calls a platform channel that **crashes under a headless VM**. Any
   Agent tool that schedules intervals must run with a Flutter binding (or the
   reminder side effect must be made injectable/optional). This is the single most
   important constraint for the tool layer.

---

## D. Recommended locations (to build in later phases — NOT implemented now)

Reuse the existing `MultiRepositoryProvider` in `lib/app/app.dart` as the single
composition root; the Agent stack is provided there alongside the domain repos.

```
lib/ai/
    core/         # AiEngine, AiRequest, AiResponse, AiMessage, AiStreamEvent, AiCapabilities   (Phase 1)
    config/       # AiConfig — provider selection, endpoint, model, mode (local/cloud)          (Phase 1, 10)
    providers/
        ollama/       # OllamaAiEngine — the ONLY place that knows Ollama's HTTP API            (Phase 2)
        llama_cpp/    # LlamaCppAiEngine                                                          (Phase 9)
    tools/        # Tool, ToolRegistry, ToolExecutor — call lib/domain services/repositories     (Phase 3)
    agent/        # AgentRuntime — controlled tool loop, tracing                                  (Phase 4)
    context/      # ContextBuilder / ContextEngine — targeted, minimal context                   (Phase 5)
    policy/       # ActionPolicy — READ_ONLY / WRITE / DESTRUCTIVE                                (Phase 6)
    models/       # ModelManager, ModelRegistry, ModelInfo                                        (Phase 8)
    analytics/    # deterministic metrics + FocusStatisticsService                               (Phase 11, and C.1)

lib/screen_ai/    # AI Assistant UI + its own bloc                                                (Phase 7)
```

**Rationale / boundary rules confirmed by the audit:**

- Tools depend on `lib/domain` only. The LLM never touches `DatabaseManager` or SQL.
- `OllamaAiEngine` / `LlamaCppAiEngine` are the only files that know their backend;
  `AgentRuntime` depends solely on the `AiEngine` abstraction.
- The Ollama provider can reuse the existing `http` dependency.
- Provide the AI stack in the same `MultiRepositoryProvider`, wiring tools to the
  already-provided domain repositories/services — no duplicate data paths.

---

## Report

**Phase:** 0 — Architectural Audit
**Status:** Complete. No code implemented, no dependencies added (as required).

**Implemented:**
- Findings only. Produced this report.

**Files changed:**
- Added `docs/PHASE_0_ARCHITECTURAL_AUDIT.md` (this file). No source changed.

**Tests:**
- None run — no code changed. (Baseline from prior work: `flutter test` = 44 passing,
  `flutter analyze` = 0 errors.)

**Architecture decisions:**
- AI layer lives under `lib/ai/` (+ `lib/screen_ai/` for UI), wired through the
  existing `MultiRepositoryProvider`; tools bind to `lib/domain`.
- The domain layer is a sufficient, clean attach point — Agent → tools → domain,
  never Agent → DatabaseManager/SQL.

**Known limitations / risks surfaced:**
- No focus/analytics aggregation exists yet (needed for focus + analytics tools).
- `FocusRepository` is concrete and imports `DatabaseManager`; propose extracting an
  interface for consistency.
- `Task` has no deadline/estimate fields; planning must use `TimeInterval`, and
  Phase 11 metrics need derived estimates.
- `createTimeInterval` carries a platform notification side effect that crashes
  headless — the tool layer must run with a Flutter binding or make it injectable.

**Recommended next step:**
- Proceed to **Phase 1 — AI Abstraction** (`lib/ai/core/` + `lib/ai/config/`),
  provider-independent, with unit tests for request/response/message serialization
  and no provider imports. Stop and report before Phase 2 (Ollama).
