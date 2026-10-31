# My Time Manager — Canonical Architecture Roadmap (Index)

> **Status:** canonical index. This is the single authoritative map of all
> architecture/roadmap work. It does **not** restate the content of the other
> reports — it links them and resolves how their phase numbering relates.
>
> **Nothing here is implemented by the existence of this document.** Items are
> marked `done` only when a referenced report verifies it; everything else is
> `planned`.

Last updated by the architecture roadmap reconciliation (documentation-only).

---

## 0. Why this file exists

The repository historically grew **two different "Phase N" sequences** that
collide:

- `Roadmap.md` numbers Phases 0–12 for **building the AI subsystem** (AI
  abstraction → Ollama → tools → agent → … → llama.cpp → personal-execution
  agent). `AI_ARCHITECTURE_REPORT.md` reports this track **implemented**.
- The Architecture Discovery Report numbers Phases 1–12 for **evolving the
  product architecture** (stabilization → domain cleanup → application layer →
  persistence refactor → goal/plan → … → analytics). This track is **not
  started**.

Both say "Phase 9" and mean different things. To avoid ambiguity without
renumbering or rewriting either body of work, this index gives each track a
**namespaced prefix** and keeps one combined, dependency-ordered view.

- **AI Track → `AI-P0 … AI-P12`** — the sequence in `Roadmap.md` (historical /
  implemented). Content there is unchanged; only the mental label is prefixed.
- **Core Track → `C1 … C18`** — the product-architecture sequence, plus the
  three new feature contracts `R`, `H`, `DR`.

"Phase N" unqualified should no longer be used in new docs. Use `AI-Pn` or `Cn`.

---

## 1. Authoritative document per concern

| Concern | Authoritative document | Notes |
|---|---|---|
| UI → domain → persistence boundary | `ARCHITECTURE_REFACTOR_REPORT.md` | Current, with one residual (see §5) |
| AI subsystem (engine/agent/tools/gateway/governance) | `AI_ARCHITECTURE_REPORT.md` | Current; AI Track reported complete |
| AI Track build plan (AI-P0…AI-P12) | `Roadmap.md` | Historical / implemented |
| Pre-AI architecture audit | `docs/PHASE_0_ARCHITECTURAL_AUDIT.md` | Historical; superseded in parts |
| Product-architecture evolution + long-term vision + new feature contracts | **this file** | Canonical index |
| User-facing feature overview | `README.md` | Product docs, not architecture authority |

---

## 2. Product vision (long-term)

My Time Manager is evolving into a **Personal Learning & Execution System**:

- Goal → Plan → Schedule → Execution → Outcome → Feedback → Replan.
- Project workspace, connected notes, documents, and diagrams.
- AI-generated courses and learning progress.
- Dictionary, translation, pronunciation, TTS, and vocabulary learning.
- Habit tracking and historical completion.
- Proactive reminders and alarms.
- Daily review and user-approved adaptive rescheduling.
- Dashboard, analytics, and other identified product capabilities.

Guardrails (unchanged from prior decisions): SQLite remains the local source of
truth; AI never writes around the authorized mutation path; AI proposes, the
user approves, deterministic application logic validates and executes; no cloud
backend / event sourcing / CQRS / microservices introduced merely to support
these features.

---

## 3. Core Track (product architecture) — canonical sequence

| ID | Phase | State |
|---|---|---|
| C1 | Stabilization (dead-code cleanup, regression tests, DB-init/transaction review, debug-output cleanup, doc alignment) | **done** (commit `fbfe0b1`) |
| C2 | Domain boundary cleanup (models → `lib/domain/models/`; domain no longer imports `data/`) | **done** |
| C3 | Thin application layer + authorized mutation workflows + side-effect coordination | **done** |
| C4 | Persistence refactor (`DatabaseManager` → per-aggregate DAOs behind a façade) | **done** |
| C5 | Goal / Plan / Milestone foundations | **done** — contract in §6 |
| C6 | Project Workspace | **done** — contract in §6 |
| C7 | Learning system (Course / Module / Lesson / Progress) | planned |
| C8 | AI foundation hardening (extends the built AI Track) | planned |
| C9 | AI-assisted planning (overlay on the deterministic DR core) | planned |
| C10 | Knowledge tools (dictionary / translate / pronounce / TTS / vocabulary) | planned |
| C11 | Semantic canvas (nodes/edges/properties; AI-editable) | planned |
| C12 | Analytics & planned-vs-actual (reuses AI-P11 deterministic metrics) | planned |
| **R** | **Reminders & Alarms** (after C3) | planned — contract in §6 |
| **H** | **Habit Tracking** (after R) | planned — contract in §6 |
| **DR** | **Daily Review & Adaptive Rescheduling** (after H + C5) | planned — contract in §6 |
| C16 | Dashboard & user-facing UI | planned (visibility preserved) |
| C17 | Integrations (Telegram, VS Code where applicable) | planned (visibility preserved) |
| C18 | Benchmarking & dogfooding / observability | planned (visibility preserved) |

The three feature contracts (`R`, `H`, `DR`) are deliberately **separate**
implementation contracts, not one combined phase.

---

## 4. Traceability — every previously identified capability preserved

| Capability | Discovery Report origin | AI Track status | Canonical home |
|---|---|---|---|
| Stabilization / baseline testing | Phase 1 | — | C1 |
| Domain-boundary cleanup | Phase 2 | — | C2 |
| Thin application layer | Phase 3 | — | C3 |
| Persistence refactoring / DB safety | Phase 4 | — | C4 |
| Goal & planning foundations | Phase 5 | — | C5 |
| Project Workspace | Phase 6 | — | C6 |
| Learning system | Phase 7 | — | C7 |
| AI foundation hardening | Phase 8 | AI-P1–P6 built | C8 |
| AI-assisted planning | Phase 9 | AI-P12 workflows exist (LLM-only) | C9 + DR overlay |
| Dictionary / translate / pronounce / TTS / vocabulary | Phase 10 | not built | C10 |
| Semantic canvas | Phase 11 | not built | C11 |
| Analytics & planned-vs-actual | Phase 12 | AI-P11 deterministic metrics built | C12 |
| Habit tracking | roadmap extension | not built | **H** |
| Reminders & alarms | roadmap extension | partial (`NotificationService`, `reminderMinutesBefore`) | **R** |
| Daily review / rescheduling | roadmap extension | partial (`AgentWorkflow` LLM prompts) | **DR** |
| Dashboard / UI | prior roadmap | AI UI built (`screen_ai`) | C16 |
| Integrations (Telegram / VS Code) | prior roadmap | not built | C17 |
| Benchmarking / dogfooding | prior roadmap | AI test suite exists | C18 |

Nothing removed; nothing renumbered inside either track.

---

## 5. Known residuals / corrections to older docs

- **C2 completed (domain/data model relocation).** The domain-shaped model
  classes moved from `lib/data/models/` and `lib/screen_focus_timer/data/` into
  `lib/domain/models/` (`model_task`, `model_list`, `model_time_interval`,
  `model_calendar_event`, `model_note`, `model_conversation`,
  `model_focus_session`, and the `Event`/`FocusInterval` barrel `models.dart`).
  `lib/domain/**` now imports **no** `data/` path — the H2 dependency-direction
  leak is closed. This was a pure file move: no field, schema, serialization,
  or behavior change. Accepted, deliberately-deferred compromises (NOT fixed in
  C2, to keep it a safe move): (1) these models still import
  `package:flutter/material.dart` for `Color`/`TimeOfDay` — purging Flutter from
  domain value types is a larger, invasive change left for a later phase;
  (2) `model_conversation` imports `lib/ai/core` value types (`AiMessage`/
  `AiToolCall`) — acceptable as those are provider-independent; (3) the legacy
  `model_measurable_task.dart` / `model_task_with_subtasks.dart` were left in
  `lib/data/models/` (one still has a live UI consumer; they are not on the
  domain-leak surface) — retiring them is deferred to a separate legacy-cleanup
  step.
- **Notification side effect still in persistence.**
  `ARCHITECTURE_REFACTOR_REPORT.md` says the UI/Bloc/Controller layer no longer
  calls `DatabaseManager` directly — true — but `DatabaseManager` itself still
  calls `NotificationService` from `insertTimeInterval` / `updateTimeInterval` /
  `deleteTimeInterval`. "No notification side effects in low-level persistence"
  is therefore **not yet satisfied**. This is resolved in **Core Track Phase R**
  by moving the side effect to the application layer.
- **Dead code:** `lib/home/data_controller.dart` (`DataController` /
  `NewDataController`) is unused (all call sites commented out) and contains a
  latent inconsistency bug in `update(event, updated)` (persists the old
  object). Removal is a **Core Track Phase C1** target.

---

## 6. Preliminary phase contracts

The approved decisions (reminder Q-R1/R2/R3, habit Q-H1/H2/H3, daily-review
Q-DR1/DR2/DR3, and Q-WORKFLOW) are **settled** and reflected below; they are not
open questions.

### Phase R — Reminders & Alarms

- **Objective:** reliable, non-duplicated reminders for tasks, intervals, and
  (via H) habits; per-item preferences + quiet hours; survives restart and
  schedule edits.
- **Dependencies:** C3. Builds on existing `NotificationService` (idempotent id
  `('<intervalId>#<minutesBefore>').hashCode & 0x7fffffff`, `tz.local`,
  exact-alarm handling, reschedule/cancel).
- **Scope:** `ReminderRule` application-level abstraction + adapters over
  `TimeInterval.reminderMinutesBefore` and `CalendarEvent.EventReminders`
  (Q-R3); an application-level ReminderCoordinator that moves the side effect
  out of `DatabaseManager` (resolves the §5 residual); a `NotificationScheduler`
  adapter interface so domain/app import no `flutter_local_notifications`;
  **stateless reconciliation** — re-derive desired state from rules, no
  persistent `NotificationSchedule` ledger (Q-R1); **wall-clock** recurrence
  (Q-R2); a pending-reminders read model derived from rules.
- **Out of scope:** cloud push; deleting/migrating legacy reminder fields; a
  notification ledger table; notification actions beyond verified plugin
  support; habit reminders (wired in H).
- **Reuse:** `NotificationService`, `AppBloc.ToggleRemindersEnabled` +
  `rescheduleAllReminders()`, `kCommonReminderMinutes` cleanup set.
- **Persistence/migration:** additive `ReminderRule` table only; legacy fields
  untouched (any schema change to legacy fields = separate approved plan).
- **Failure modes / policies:** repeated edits → reconcile to desired set,
  dedupe by deterministic id; cancel-after-schedule → cancel by id; app/device
  restart → re-derive from rules on launch; permission denied/revoked → degrade
  + non-blocking banner, never crash; multiple rules per item → distinct ids;
  completed-before-fire → suppress on reconcile; DST/timezone → wall-clock; OS
  cannot schedule all desired → prioritize nearest + important, document drop
  policy.
- **Platform notes:** Android 12+ exact-alarm requires a settings redirect
  (handled lazily today); `flutter_local_notifications` cannot enumerate all
  OS-scheduled notifications on every platform, so reconciliation must be
  derive-and-overwrite by deterministic id, not read-back.
- **Tests/acceptance:** idempotent reconcile (apply twice → one notification);
  edit reschedules exactly once; `DatabaseManager` CRUD no longer calls
  `NotificationService`; domain/app import no platform notification API;
  existing `TimeInterval` reminder behavior preserved.
- **Rollback:** additive-only; feature flag to fall back to current direct
  scheduling; legacy fields intact.
- **Open:** R-a (iOS pending-notification limit drop policy); R-b
  (nonexistent/ambiguous local times under DST).

### Phase H — Habit Tracking

- **Objective:** create/schedule/track recurring habits; trustworthy
  streaks/rates derived from records; history survives rule changes.
- **Dependencies:** R, C3.
- **Scope:** `Habit` (recurrence via reused `RepeatRule`; optional target;
  per-habit "partial counts toward streak" flag per Q-H1; nullable Goal/Project
  links); `HabitOccurrence` with explicit outcomes **completed / partial /
  skipped / missed / pending**; statistics computed from occurrences + policy
  (mirror `FocusStatisticsService`); **archive-by-default** retaining history
  (Q-H2); optional **read-only calendar projection** referencing habit +
  occurrence (Q-H3).
- **Out of scope:** materializing habits as Tasks/TimeIntervals; AI habit
  suggestions; dashboards (C12); hard delete (separate explicit operation).
- **Reuse:** `RepeatRule` / `RecurrenceService`, `FocusStatisticsService`
  pattern, repository + adapter + DI pattern, the in-memory FFI test harness
  (`DatabaseManager.resetForTesting`).
- **Persistence/migration:** additive `Habit` + `HabitOccurrence` tables +
  `HabitRepository`; no change to Task/TimeInterval/FocusSession; the projection
  is a read model, not an events table.
- **Failure modes / policies:** rule change after history → past occurrences
  immutable, only future recompute; long offline → occurrences become `missed`
  deterministically vs `now` at read time (nothing auto-written in background);
  timezone change → occurrence "day" anchored to the habit's stored local day;
  archive → stop future generation + reminders, keep history; policy change →
  never rewrite historical rows (reports recompute from policy + rows).
- **Tests/acceptance:** stats reproducible purely from occurrence rows; rule
  change never rewrites outcomes; outcome set is exactly the five states;
  projection completes via the habit workflow (not a calendar edit).
- **Rollback:** additive tables only; dropping the feature leaves other data
  intact.
- **Open:** H-a (does `skipped` pause or break a streak? proposed: pause).

### Phase DR — Daily Review & Adaptive Rescheduling

- **Objective:** at a configurable time, show correctly-categorized unresolved
  work and let the user Do-now / Reschedule / Split / Keep-pending / Skip-cancel
  with deterministic, conflict-checked, user-confirmed changes.
- **Dependencies:** H, C5, R.
- **Scope:** deterministic review query (categorize from existing repos);
  availability/working-hours model (empty slot is not automatically free);
  deterministic scheduler + conflict checker; **transient** `RescheduleProposal`
  with affected ids, current vs proposed values, conflicts/assumptions, source,
  and a fingerprint/version to detect stale input (Q-DR2); validate-at-commit
  (re-read authoritative state); apply via the authorized mutation path +
  existing `ConfirmationHandler`; **ask the user when duration is unknown**
  (Q-DR3); computed on demand, **no history table** (Q-DR1); deterministic core
  + optional AI overlay coexist (Q-WORKFLOW).
- **Out of scope:** persistent review/proposal tables; AI/optimization solver
  (C9 overlay); silently moving deadlines/recurring/fixed appointments;
  auto-apply without confirmation; deprecating `AgentWorkflow`.
- **Reuse:** `AgentWorkflow.dailyPlanning/rescheduling` as UX framing + AI
  overlay; `ConfirmationHandler` / `ActionPolicy`; `TimeIntervalProgressService`
  ("started but incomplete"); repositories for incomplete-work queries;
  `productivity_metrics` for context.
- **Persistence/migration:** none required for proposals/review; applied moves
  persist via the normal authorized workflow.
- **Failure modes / policies:** no unfinished work → positive empty state;
  overcapacity → propose only what fits, rest "keep pending", never overfill;
  unknown duration → ask (Q-DR3), else leave unscheduled + explain; deadline, no
  slot → surface unresolvable conflict, don't move the deadline; proposed slot
  conflict → flagged, excluded from auto-apply; task changed after proposal →
  re-validate at commit, reject stale; partial acceptance → apply accepted
  subset atomically; full rejection → no-op; recurring/habit involved → operate
  on the occurrence, never the rule; mid-batch apply failure → per-item
  transactional, report partial result, never leave a half-applied set silently.
- **Tests/acceptance:** categorization deterministic + unit-tested; nothing
  applies without confirmation; commit re-validates and rejects stale/
  conflicting; fixed appointments/deadlines never moved silently; respects
  availability limits; repeated review produces no duplicate/unintended
  mutations.
- **Rollback:** proposals transient/reversible; feature flag disables the review.
- **Open:** DR-a (atomicity when a multi-item accepted batch partially fails);
  DR-b (definition of a "user-fixed" appointment that must never auto-move).

### Phase C5 — Goal / Milestone foundations (contract, implemented)

- **Scope delivered:** domain models (`Goal`, `Milestone`, `GoalLink` in
  `lib/domain/models/`), one aggregate `GoalDao`, `GoalRepository` +
  `SqliteGoalRepository`, pure `GoalProgressService`, DI in `app.dart`,
  Trash/Archive + backup/import integration, tests. No goal UI, no AI tools.
- **No separate Plan entity.** A goal's "plan" = its milestones + linked items.
- **Schema v13 (strictly additive):** new tables `goals` (soft-delete +
  archive columns, `status` TEXT active/paused/completed/abandoned),
  `milestones`, `goal_links` (`goalId`, nullable `milestoneId`, `entityType`,
  `entityId`, `createdAt`, `deviceId`; `UNIQUE (entityType, entityId, goalId)`)
  plus indexes, and trigger `delete_goal_links_of_task` (AFTER DELETE ON tasks →
  removes `entityType='task'` links; also fires when a tasklist hard delete
  cascades into tasks). `GoalDao.createSchema` is the single SQL source for
  both `_onCreate` and the `_onUpgrade` `oldVersion < 13` branch. No existing
  table/column changed.
- **FK rules:** `goalId` → `goals` `ON DELETE CASCADE` (milestones and links);
  `goal_links.milestoneId` → `milestones` `ON DELETE SET NULL` (deleting a
  milestone degrades its links to direct goal links instead of detaching the
  task from the goal).
- **Extensible links:** `entityType` is a free TEXT (`GoalEntityType.task =
  'task'` today); `'calendarEvent'`, `'habit'`, `'note'` can be added later
  without migration, and unknown types never break `fromMap`.
- **Progress is derived, never stored** (no manual override):
  - "Live" linked task = linked task visible in `TaskRepository.getTasks()`
    (exists, not trashed, not archived); missing/trashed/archived links are
    ignored in numerator and denominator; duplicate ids count once.
  - Milestone: `isCompleted` flag → 1.0; else live completed / live total
    (0 live → 0.0). Done iff ratio == 1.0. The service never writes the flag.
  - Goal: `status == completed` → 1.0; else with ≥1 milestone → done
    milestones / total milestones (direct links reported, not counted); with
    0 milestones → live completed direct-linked tasks / live direct-linked
    tasks (0 live → 0.0).
- **Trash / Archive:** goals join `_softDeleteTables` and the
  `TrashedItemType` / `ArchivedItemType` enums. Goal soft-delete/archive do
  **not** cascade (milestones/links are only reachable through the goal and
  reappear on restore/unarchive); hard delete (permanent delete, empty trash,
  expired purge) cascades via FK. Task soft-delete/archive keeps its links.
- **Backup / import:** `goals`, `milestones`, `goal_links` appended to
  `allDataTables` and `ImportService._importOrder` (parents first). Import of
  these 3 tables is **update-first-then-insert** (not `INSERT OR REPLACE`,
  which would DELETE + INSERT and fire the CASCADE / SET NULL on local
  children); other tables keep REPLACE.
- **Known gap (pre-existing, out of scope):** `ImportService._importOrder`
  still lacks `calendar_events` / `notes`.

### Phase C6 — Project Workspace (contract, implemented)

- **Scope delivered:** domain models (`Project` with `ProjectStatus`
  active/onHold/completed/cancelled, `ProjectItem` + `ProjectEntityType` in
  `lib/domain/models/`), one aggregate `ProjectDao`, `ProjectRepository` +
  `SqliteProjectRepository`, pure `ProjectWorkspaceService` (read model), DI in
  `app.dart`, Trash/Archive + backup/import integration, localized strings, and
  a **read-only** UI: drawer entry "Projects" → `ProjectsListScreen` →
  `ProjectWorkspaceScreen`. No create/edit/link UI, no AI tools yet.
- **Project is a new entity**, not a TaskList. Its parts are linked through
  `project_items`; the workspace is computed, never stored.
- **Schema v14 (strictly additive):** new tables `projects` (title,
  description, color, `status` TEXT default `'active'`, `startDate`,
  `targetDate`, `createdAt`, `updateTimeStamp`, soft-delete + archive columns,
  `deviceId`) and `project_items` (`projectId` NOT NULL, `entityType`,
  `entityId`, `sortOrder` default 0, `createdAt`, `deviceId`); indexes
  `idx_project_items_projectId`, UNIQUE `idx_project_items_unique
  (projectId, entityType, entityId)`, `idx_project_items_entityRef
  (entityType, entityId)`; triggers `delete_project_items_of_{tasklist, task,
  note, calendar_event, goal}` (AFTER DELETE on the entity table → remove the
  matching items). `ProjectDao.createSchema` is the single SQL source for both
  `_onCreate` and the `_onUpgrade` `oldVersion < 14` branch. No existing
  table/column changed.
- **FK rules:** `project_items.projectId` → `projects` `ON DELETE CASCADE`.
  Hard-deleting a project removes only its items, **never** the linked
  entities. There is no FK to entity tables (`entityType` is extensible:
  `taskList`, `task`, `note`, `calendarEvent`, `goal` today); the triggers
  clean up items on entity hard delete. DAO inserts never use REPLACE.
- **Membership:** many-to-many; an entity is in a project at most once
  (`addItem` is an upsert that only updates `sortOrder` when given; throws
  `ArgumentError` for an unknown project or empty `entityType`).
- **Workspace rules (derived, never stored):**
  - "Live" entity = visible in its repository list (exists, not trashed, not
    archived). Items pointing elsewhere, or with an unknown `entityType`, are
    skipped and counted in `ignoredItemCount`.
  - Items are walked by `sortOrder`, then `createdAt`; duplicates are taken once.
  - A live linked task list contributes its live tasks **implicitly**
    (`viaTaskListId`); a directly linked task is `isDirect`. A task reached
    both ways appears once with both flags.
  - Goals carry their C5 `GoalProgress` (passthrough from
    `GoalProgressService`, not recomputed).
  - Task counts and completion ratio are derived (0 tasks → 0.0).
- **Trash / Archive:** projects join `_softDeleteTables` and the
  `TrashedItemType` / `ArchivedItemType` enums. Project soft-delete/archive do
  **not** cascade (items are kept and reappear on restore/unarchive); hard
  delete (permanent delete, empty trash, expired purge) cascades to items via FK.
- **Backup / import:** `projects`, `project_items` appended to `allDataTables`
  and at the end of `ImportService._importOrder` (after every entity table).
  Both use **update-first-then-insert** (REPLACE would cascade-delete a
  project's items); `project_items` uses `createdAt` as its update timestamp.

---

## 7. Integration notes

- **AI workflows:** `AgentWorkflow` (`dailyPlanning` / `weeklyReview` /
  `rescheduling`) are LLM-prompt recipes on the shared agent loop; writes still
  pass `ActionPolicy` + confirmation. Per Q-WORKFLOW they are **kept** — DR owns
  the deterministic authoritative core, and the AI workflow becomes the optional
  overlay that feeds proposals into DR's validator rather than writing around it.
  No deprecation.
- **Reminders:** two reminder representations exist today
  (`TimeInterval.reminderMinutesBefore`, `CalendarEvent.EventReminders`); only
  the former is wired to `NotificationService`. Phase R introduces `ReminderRule`
  as the single application-level abstraction with adapters over both, with no
  duplicated reminder state and no legacy deletion.

---

## 8. Remaining open questions (not settled by prior approvals)

- **R-a:** iOS pending-local-notification limit — drop policy when desired
  reminders exceed it (proposed: keep nearest-in-time + highest-priority).
- **R-b:** nonexistent/ambiguous wall-clock times under DST (proposed:
  nonexistent → next valid instant; ambiguous → first occurrence).
- **H-a:** does `skipped` pause or break a streak (proposed: pause)?
- **DR-a:** atomicity when applying a multi-item accepted batch and one fails
  (proposed: per-item transactional + report partial result).
- **DR-b:** definition of a "user-fixed" appointment that must never auto-move
  (proposed: a CalendarEvent marked busy/opaque, or an explicit lock flag).

---

## 9. Next approval boundary

The next implementation step is **Core Track Phase C1 (Stabilization)**, scoped
exactly as in the Architecture Discovery Report: safe dead-code cleanup
(including `DataController`), regression tests, DB-init/transaction review,
debug-output cleanup, and documentation alignment. C1 introduces **no** new
models, schema changes, `DatabaseManager` decomposition, or any of R/H/DR.
R cannot begin before C1 and C3 land.
