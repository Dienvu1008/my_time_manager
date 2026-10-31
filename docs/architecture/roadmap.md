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
| C7 | Learning system (Course / Module / Lesson / Progress) | **done** — contract in §6 |
| C8 | AI foundation hardening (extends the built AI Track) | **done** — C8a + C8b, contract in §6 |
| C9 | AI-assisted planning (overlay on the deterministic DR core) | planned |
| C10 | Knowledge tools (dictionary / translate / pronounce / TTS / vocabulary) | planned |
| C11 | Semantic canvas (nodes/edges/properties; AI-editable) | planned |
| C12 | Analytics & planned-vs-actual (reuses AI-P11 deterministic metrics) | planned |
| **R** | **Reminders & Alarms** (after C3) | **done** — contract in §6 |
| **H** | **Habit Tracking** (after R) | in progress — H1 data layer done (v18); contract in §6 |
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
- **Notification side effect in persistence — resolved.** `DatabaseManager`
  used to call `NotificationService` from `insertTimeInterval` /
  `updateTimeInterval` / `deleteTimeInterval`. C3 removed that call (the
  repository calls the application-level `ReminderScheduler` port instead), and
  Phase R puts the `ReminderCoordinator` behind that port (plus a reconcile
  trigger on the calendar / task / reminder-rule repositories). "No
  notification side effects in low-level persistence" is now satisfied.
- **Dead code:** `lib/home/data_controller.dart` (`DataController` /
  `NewDataController`) is unused (all call sites commented out) and contains a
  latent inconsistency bug in `update(event, updated)` (persists the old
  object). Removal is a **Core Track Phase C1** target.

---

## 6. Preliminary phase contracts

The approved decisions (reminder Q-R1/R2/R3, habit Q-H1/H2/H3, daily-review
Q-DR1/DR2/DR3, and Q-WORKFLOW) are **settled** and reflected below; they are not
open questions.

### Phase R — Reminders & Alarms (contract, implemented)

- **Scope delivered:**
  - **Schema v16 (strictly additive):** table `reminder_rules` (`id`,
    `entityType` free TEXT, `entityId`, `kind` offset/absolute,
    `offsetMinutes`, `absoluteAt` wall-clock TEXT `YYYY-MM-DDTHH:MM`,
    `enabled`, `priority`, `createdAt`, `updateTimeStamp`, `deviceId`; no FK,
    no REPLACE), index `idx_reminder_rules_entity (entityType, entityId)`, and
    AFTER DELETE triggers removing the rules of a hard-deleted timeinterval /
    calendar event / task. `ReminderRuleDao.createSchema` is the single SQL
    source for `_onCreate` and `_onUpgrade` `oldVersion < 16`. Model
    `ReminderRule` + `WallClock`, `ReminderRuleRepository` +
    `SqliteReminderRuleRepository` (`replaceRulesFor` per entity + kind).
  - **Legacy adapters (Q-R3):** `TimeInterval.reminderMinutesBefore` and
    `CalendarEvent` popup overrides stay the source of offset reminders
    (`useDefault` → no local reminder; email overrides ignored); explicit
    rules are merged in.
  - **Deterministic ids:** legacy interval offsets keep
    `('<intervalId>#<m>').hashCode & 0x7fffffff` (old and new paths overwrite
    each other); every other reminder uses FNV-1a 32-bit over a stable key
    (`calendarEvent:<id>#<m>`, `rule:<ruleId>`, `@<occurrence>` for recurring
    events).
  - **Stateless reconciliation (Q-R1):** reset reconcile on launch / settings
    change (`cancelAll` + schedule the selected set); incremental reconcile
    after repository mutations (cancel `(snapshot ∪ alsoCancel) − selected`,
    schedule new or changed payloads). The snapshot lives in memory only; runs
    are serialized and coalesced. Applying twice makes zero calls the second
    time. Residual: a row hard-deleted by an SQL cascade mid-session keeps its
    notification until the next launch reset.
  - **Wall-clock / R-b:** anchors and absolute rules are resolved from local
    wall fields in `tz.local`; recurring calendar events are expanded over a
    30-day horizon.
  - **R-a:** the planner sorts by fire time, then priority, then id, and keeps
    the first N (iOS/macOS 64, Android 400, others 64); the rest are reported
    as deferred and scheduled by later reconciles.
  - **Quiet hours:** a fire time inside `[start, end)` (may cross midnight)
    moves to the next `end`, DST-safe; an offset reminder whose shifted time
    falls after its anchor is suppressed. Absolute reminders always shift.
  - **Policies:** past fire times dropped; completed intervals, cancelled /
    trashed / archived events, completed or missing tasks, disabled rules and
    unknown entity types suppressed. Permission denied → still scheduled,
    `health.permission = denied`, non-blocking banner; scheduler errors are
    counted, never thrown. Exact alarms are used only when already allowed;
    permission requests are user-initiated.
  - **Layering:** `NotificationScheduler` port in
    `lib/application/reminders/`; `lib/domain` / `lib/application` import no
    `flutter_local_notifications` / `flutter_timezone` /
    `notification_service.dart` (enforced by a test). Platform adapters live in
    `lib/data/notifications/`; wiring in `lib/app/reminder_module.dart`.
  - **Feature flag:** setting "Smart reminder scheduling"
    (`reminderCoordinatorEnabled`, default on). Off → the pre-R direct
    interval scheduling (`NotificationReminderScheduler`); legacy fields are
    untouched either way.
  - **UI entry points:** drawer "Reminders" → Upcoming reminders screen
    (read model with deferred / quiet-hours chips and permission banner);
    Settings reminders card (existing switch + quiet hours + flag + link);
    `AlarmListTile` with edit / max count / localized labels; the calendar
    event page has "Use calendar default", multi-offset popup overrides (max 5
    incl. preserved non-popup overrides) and specific-time reminders saved as
    `absolute` rules.
  - **Backup / import:** `reminder_rules` appended to `allDataTables` and
    `ImportService._importOrder`, imported update-first-then-insert.
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
- **Settled:** R-a — over the platform pending limit, keep the nearest in
  time, then higher priority, then lower id; the rest are deferred to later
  reconciles. R-b — a nonexistent local time (DST gap) resolves to the
  transition instant (first instant whose wall time is ≥ the request); an
  ambiguous one (DST overlap) resolves to its first occurrence.

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
- **Schema:** H must use schema **v18** (v17 is taken by C8b `ai_action_log`).
- **H-a (approved):** `skipped` **pauses** a streak (no add, no break).
- **H1 delivered (data layer + statistics, no UI):**
  - **Schema v18 (strictly additive):** `habits` (title, description, color,
    `recurrence` = `RepeatRule` JSON, `targetAmount` REAL, `unit`,
    `partialCountsTowardStreak`, `startDate` / `endDate` local day
    `yyyy-MM-dd`, `reminderTime` `HH:mm` (for H3), `isArchived`, `archivedAt`,
    `createdAt`, `updateTimeStamp`, `deviceId`; no soft-delete columns) and
    `habit_occurrences` (`habitId` FK → habits `ON DELETE CASCADE`,
    `localDate`, `outcome` TEXT with `CHECK` in the five states, `amount`,
    `note`, `recordedAt`, `deviceId`) + UNIQUE index
    `idx_habit_occurrences_habit_date (habitId, localDate)`; triggers
    `delete_goal_links_of_habit` / `delete_project_items_of_habit`.
    `HabitDao.createSchema` is the single SQL source for `_onCreate` and the
    `oldVersion < 18` branch.
  - **Domain:** `Habit`, `HabitOccurrence` + `HabitOutcome` (unknown stored
    value → `pending`, i.e. unresolved), `HabitDay` local-day helpers;
    `RepeatRule` gained JSON (`toMap/toJson/fromMap/fromJson`, tolerant), value
    equality and DST-safe day queries (`matchesPattern`, `occurrencesBetween`,
    `occursOn`) with the same semantics as `generateStartDates` but no
    1000-occurrence cap. `HabitRepository` + `SqliteHabitRepository`:
    CRUD, `archiveHabit` / `unarchiveHabit` (default removal, history kept),
    `deleteHabitPermanently` (explicit hard delete), `recordOutcome` (upsert,
    update-first-then-insert, never REPLACE), `clearOutcome`,
    `getOccurrence`, `occurrencesOf(habitId, {from, to})`. Occurrence id is
    deterministic `'<habitId>:<yyyy-MM-dd>'` so the same day recorded on two
    devices merges by id on import. DI: `HabitRepository`,
    `HabitStatisticsService` in `app.dart`.
  - **Derivation (`HabitStatisticsService`, pure, nothing written):** only
    user-recorded rows are stored. A recorded completed / partial / skipped /
    missed row is used as-is on any day (also days the current rule no longer
    schedules). An unrecorded scheduled day — or one recorded as `pending` /
    unknown — is derived: before today → `missed`, today or later →
    `pending`. Scheduled days come from the **current** rule anchored at
    `startDate`, bounded by `endDate` and the archive day. A rule change never
    rewrites rows; derived (unrecorded) days follow the current rule, also for
    past days (documented choice).
  - **Streaks:** completed adds; partial adds iff
    `partialCountsTowardStreak`, otherwise pauses; skipped pauses; missed
    breaks; pending (today/future) pauses, so today's pending never breaks the
    current streak; unrecorded non-scheduled days are ignored; only days ≤
    today are walked. `currentStreak` = run ending today, `bestStreak` =
    longest run in history.
  - **Completion rate** over a window (≤ today): (completed + partial if the
    flag is set) / (completed + partial + missed); skipped and pending are
    excluded; 0 resolved → 0. Plus per-outcome counts (all 5 keys),
    scheduled-day count and the list of resolved days for a range (for H2/H3).
  - **Archive / backup:** `ArchivedItemType.habit` (`supportsTrash = false`:
    no "move to trash" on the archive screen; the archive query skips the
    `isDeleted` filter for it; label localized in 13 locales). `habits`,
    `habit_occurrences` appended to `allDataTables` and
    `ImportService._importOrder` (parents first), both update-first-then-insert;
    keep-newest uses `updateTimeStamp` / `recordedAt`.
  - **Links:** `GoalEntityType.habit` / `ProjectEntityType.habit` constants
    only (no repository link methods yet). Habit links do not count toward
    goal progress; `'habit'` is not in `ProjectEntityType.supported`, so
    `ProjectWorkspaceService` counts habit items in `ignoredItemCount`.
- **H2 delivered (habit UI, no schema change):**
  - **Entry point:** drawer item "Habits" / "Thói quen" (next to Goals /
    Projects / Courses) → `HabitsListScreen` (`lib/screen_habits/`).
    Archived habits stay reachable from the existing Archive screen.
  - **`HabitsListScreen`:** active habits with color, current-streak chip and
    today's derived state (pending / completed / partial / skipped, or "not
    scheduled today"); quick actions for today when scheduled (Complete /
    Partial / Skip → `recordOutcome(habitId, today, …)`) plus Undo
    (`clearOutcome`) when recorded; empty state with CTA; FAB to create.
  - **`HabitFormScreen`:** title (required), description, color, recurrence
    via the existing `RepeatListTile` (gained optional `initialRule` /
    `showNone`; defaults keep time-interval behavior), optional target amount
    + unit, "partial counts toward streak", start date (required, default
    today), optional end date (≥ start), reminder time `HH:mm` (stored only;
    scheduling is H3). `DateField` gained optional `clearable` / `errorText`.
  - **`HabitDetailScreen`:** header, statistics (current / best streak,
    completion rate, counts per outcome) and the last 30 resolved days newest
    first (derived days faded + "not recorded"); tapping a day ≤ today opens a
    sheet to set completed / partial / skipped / missed (+ amount if target,
    note) or clear; changing a past day asks for confirmation. Menu: Edit,
    Archive (confirm), Delete permanently (confirm mentions history loss).
  - All screens take an injectable clock (`DateTime Function()? now`); strings
    localized in 13 locales (`habit_labels.dart` for outcome labels / icons).
  - **Still H3:** calendar projection, habit reminders, goal/project linking UI.

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
  Trash/Archive + backup/import integration, tests. Goal UI was added later
  (see "Goal / Project UI" below); no AI tools.
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
- **Known gap (pre-existing) — fixed:** `ImportService._importOrder` now
  includes `calendar_events` (after `events`, FK to `tasklists`) and `notes`
  (after `focus_sessions`), both before `goals`. Neither has FK children, so
  both keep REPLACE semantics; keep-newest compares `updated` / `updatedAt`.

### Phase C6 — Project Workspace (contract, implemented)

- **Scope delivered:** domain models (`Project` with `ProjectStatus`
  active/onHold/completed/cancelled, `ProjectItem` + `ProjectEntityType` in
  `lib/domain/models/`), one aggregate `ProjectDao`, `ProjectRepository` +
  `SqliteProjectRepository`, pure `ProjectWorkspaceService` (read model), DI in
  `app.dart`, Trash/Archive + backup/import integration, localized strings, and
  a UI: drawer entry "Projects" → `ProjectsListScreen` →
  `ProjectWorkspaceScreen` (originally read-only; create/edit/link was added
  later, see "Goal / Project UI" below). No AI tools yet.
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

### Phase C7 — Learning system (contract, implemented)

- **Scope delivered:** domain models (`Course` with `CourseStatus`
  active/paused and `CourseSource` manual/aiGenerated, `CourseModule`,
  `Lesson` + `LessonLink`, `LessonProgress` + `LessonStatus`
  notStarted/inProgress/completed in `lib/domain/models/`), one aggregate
  `LearningDao`, `LearningRepository` + `SqliteLearningRepository`, pure
  `LearningProgressService`, DI in `app.dart`, Trash/Archive + backup/import
  integration, goal/project integration, localized strings, and a course /
  lesson UI: drawer entry "Courses" → `CoursesListScreen` →
  `CourseDetailScreen` → `LessonScreen` (plus `CourseFormScreen`). No AI tools
  yet, no linking UI (linking is repository-only).
- **Schema v15 (strictly additive):** new tables `courses` (title,
  description, color, `source` default `'manual'`, `status` default
  `'active'`, `createdAt`, `updateTimeStamp`, soft-delete + archive columns,
  `deviceId`), `course_modules` (`courseId` NOT NULL, title, description,
  `sortOrder`), `lessons` (`moduleId` NOT NULL, title, `contentJson`
  (AppFlowy doc), `links` JSON `[{title,url}]`, `noteIds` JSON, `sortOrder`),
  `lesson_progress` (`lessonId` NOT NULL UNIQUE, `status` default
  `'notStarted'`, `startedAt`, `completedAt`, `lastOpenedAt`); indexes
  `idx_course_modules_courseId`, `idx_lessons_moduleId`; triggers
  `delete_goal_links_of_course` / `delete_project_items_of_course` (AFTER
  DELETE ON courses). `LearningDao.createSchema` is the single SQL source for
  both `_onCreate` and the `_onUpgrade` `oldVersion < 15` branch. No existing
  table/column changed.
- **FK rules:** `courses` → `course_modules` → `lessons` → `lesson_progress`,
  each `ON DELETE CASCADE`. Lessons store only `moduleId` (course reached via
  JOIN). DAO inserts never use REPLACE. Corrupt `links` / `noteIds` JSON reads
  as `[]`; dangling note ids are ignored; the UI accepts only http/https URLs.
- **Progress identity and transitions:** `lesson_progress.id == lessonId`
  (one row per lesson, merges cleanly across devices). Open → `inProgress`
  (`startedAt ??= now`, completed stays completed, `lastOpenedAt = now`);
  mark complete → `completed` + `completedAt`; mark incomplete → back to
  `inProgress`, `completedAt = null` (no row → nothing written).
- **Progress is derived, never stored** (no manual override, no stored
  "completed" course status):
  - Lesson status = its progress row; no row → notStarted. Rows of lessons
    outside the module / course are ignored.
  - Module: completed / total lessons (0 → 0.0); done iff ≥1 lesson and all
    completed.
  - Course: completed / total lessons across all modules (weighted by lesson);
    0 lessons → 0.0, not done. Done iff ≥1 lesson, all completed **and every
    module is done** — an empty module keeps the course not done even if the
    ratio reads 1.0. Done-module and in-progress counts are reported only.
- **Goal integration:** `GoalEntityType.course`, `linkCourse` /
  `unlinkCourse` on `GoalRepository`. Course progress does **not** count
  toward goal progress (`GoalProgressService` still counts tasks only).
- **Project integration:** `ProjectEntityType.course` (in `supported`);
  `ProjectWorkspaceService` exposes `courses` (`WorkspaceCourse` with its
  derived `CourseProgress`); trashed / archived / missing courses go to
  `ignoredItemCount`. `ProjectWorkspaceScreen` shows a read-only "Courses"
  section with the percent.
- **Editor reuse:** the AppFlowy editor block was extracted to
  `lib/shared/appflowy_content_editor.dart`; `NoteEditorPage` and
  `LessonScreen` share it with identical config.
- **Trash / Archive:** courses join `_softDeleteTables` and the
  `TrashedItemType` / `ArchivedItemType` enums. Course soft-delete/archive do
  **not** cascade; hard delete cascades via FK and triggers. Modules and
  lessons have no trash (hard delete after confirm).
- **Backup / import:** the 4 tables are in `allDataTables` and
  `ImportService._importOrder` after `notes` and before `goals` (parents
  first), all **update-first-then-insert**; keep-newest uses
  `updateTimeStamp`.

### Goal / Project UI (implemented)

- **Screens:** `GoalsListScreen`, `GoalFormScreen`, `GoalDetailScreen`
  (milestones: add/edit/delete/reorder/complete; link/unlink tasks and
  courses, directly or per milestone) in `lib/screen_goals/`;
  `ProjectFormScreen` plus extended `ProjectsListScreen` (create) and
  `ProjectWorkspaceScreen` (edit project, add/remove linked items) in
  `lib/screen_projects/`.
- **Entry points:** drawer entries "Goals" and "Projects".
- **Shared pickers / fields:** `lib/shared/entity_picker.dart` +
  `lib/shared/entity_picker_sources.dart` (searchable `EntityPickerScreen`;
  loaders for task lists, tasks, notes, goals, calendar events, courses), plus `color_choice_field.dart`, `date_field.dart`,
  `confirm_dialog.dart`.
- **New repository method:** `GoalRepository.reorderMilestones` (persists
  milestone `sortOrder`). No schema change.

### Phase C8a — AI tools for new entities (implemented)

- **Tools** (`lib/ai/tools/domain/{goal,project,learning,note,reminder}_tools.dart`):
  - readOnly: `list_goals`, `get_goal`, `list_projects`,
    `get_project_workspace`, `list_courses`, `get_course_progress`,
    `search_notes`, `list_upcoming_reminders`.
  - write (confirmation required): `create_goal`, `update_goal`,
    `create_milestone`, `update_milestone`, `link_task_to_goal`,
    `create_project`, `add_project_item`, `set_lesson_completed`,
    `add_interval_reminder` (saves a `ReminderRule.offset` via
    `ReminderRuleRepository`; the coordinator reconciles).
  - destructive (confirmation required, denied in read-only mode):
    `archive_goal`, `trash_goal`, `archive_project`, `trash_project`,
    `archive_course`, `trash_course`. Trash = soft delete; no hard-delete
    tools.
- **Confirmation text:** optional `ConfirmationDescriber` on tools, used by
  `ToolExecutor` when no summarizer is given; existing tools unchanged.
- **Untrusted content:** user-authored descriptions / note snippets / lesson
  content are returned as `{untrusted: true, text, truncated?}`
  (`ToolViews.untrusted` / `snippet`, ≤300 chars for snippets).
- **ContextBuilder:** optional sections for active goals (with progress %),
  active projects and in-progress lessons, each capped at 5, deterministic
  order, omitted when empty.
- **Layering:** `lib/ai/tools` and `lib/ai/context` do not import `lib/data`
  or `sqflite` (enforced by `test/ai/tools/ai_tools_layering_test.dart`).
  No schema change.

### Phase C8b — AI hardening (implemented)

- **Schema v17 (strictly additive):** table `ai_action_log` (`id`,
  `createdAt` UTC ISO, `toolName`, `policyLevel` = tool risk `write` |
  `destructive`, `policyMode` (ActionPolicy mode or NULL), `argsSummary`,
  `outcome`, `resultSummary`, `errorMessage`, `conversationId` nullable,
  `deviceId`) + index `idx_ai_action_log_created`. No FK (deleting a chat
  keeps the audit), no trigger. Single SQL source `AiActionLogDao.createSchema`
  called from `_onCreate` and the `oldVersion < 17` branch. Domain model
  `AiActionLogEntry` / `AiActionOutcome`, port `AiActionLogRepository`,
  adapter `SqliteAiActionLogRepository`.
- **Logging choke point:** `ToolExecutor` (every model call, structured or
  text-parsed, goes through it) records via an injected `AiActionLog`
  (`lib/ai/policy/ai_action_log.dart`; default `NoOpAiActionLog`, production
  `RepositoryAiActionLog` wired in `AiAssistantEntry` → controller, with the
  current conversation id). Only WRITE / DESTRUCTIVE tools resolved in the
  registry are logged; read-only and unknown tools are not. Outcomes:
  `executed` (tool success), `declined` (user said no), `failed` (tool
  failure, thrown error, malformed JSON args), `deniedByPolicy` (ActionPolicy
  deny e.g. read-only mode, or a `ToolPermissionCheck` deny). Logging never
  throws and never changes the `ToolResult`; confirmation UX unchanged.
- **Redaction (`AiActionLogFormat`):** keys sorted; ids / numbers / bools /
  short tokens kept; `title` / `name` / `query` capped at 40 chars;
  descriptions, content, location, notes and other free text stored only as
  `<N chars>`; lists as `[N items]`, maps as `{…}`; args ≤ 500 chars,
  result summary (ids + capped title, else `ok`) ≤ 200, error `code: message`
  ≤ 300.
- **Retention:** newest **1000** entries and nothing older than **90 days**
  (`AiActionLogRetention`), purged best-effort on app start in `main.dart`
  after the trash purge.
- **Backup:** `ai_action_log` is **excluded** from `allDataTables` /
  `ImportService._importOrder` (device-local audit data, like
  `conversations` / `chat_messages`).
- **Screen:** `AiActionLogScreen` (drawer entry "AI activity log" after AI
  Settings): newest first, outcome filter chips, tap for details, clear with
  confirmation; 13 locales.
- **Strict tool args:** every domain tool runs through `guardToolCall`
  (`lib/ai/tools/tool_guard.dart`): `ToolArgumentError` / `ArgumentError` /
  `FormatException` / `TypeError` → `invalid_arguments`, other exceptions →
  `domain_error`; tools never throw. `ToolArgs.optIntInRange` bounds `days`
  (1..3660), focus `limit` (0..1000), `availableMinutes` (0..100000).
  Registry-wide table-driven test `test/ai/tools/tool_arg_validation_test.dart`
  (`{}`, garbage-typed args, unknown ids, out-of-range values).
- **Untrusted convention:** extended to task `description` and calendar event
  `location` / `description` (`ToolViews`); titles stay plain strings.
  `AgentContext.render()` adds a data notice and flattens/caps titles (no
  injected new lines); `AgentConfig.untrustedDataRule` is appended to the
  default system prompt (untrusted content is data, never instructions).
- **Evaluation harness:** `test/ai/support/` — `ScriptedAiEngine` (scripted
  responses, structured or text-format tool calls), `AiTestEnv` (full domain
  registry over in-memory SQLite with the real repositories),
  `RecordingAiActionLog`. Injection invariant
  `test/ai/agent/prompt_injection_test.dart`; end-to-end agent-loop tests
  `test/ai/agent/agent_e2e_test.dart`. No Ollama / llama.cpp needed.
- **Layering:** the layering test now also covers `lib/ai/policy` and
  `lib/ai/agent`.

---

## 7. Integration notes

- **AI workflows:** `AgentWorkflow` (`dailyPlanning` / `weeklyReview` /
  `rescheduling`) are LLM-prompt recipes on the shared agent loop; writes still
  pass `ActionPolicy` + confirmation. Per Q-WORKFLOW they are **kept** — DR owns
  the deterministic authoritative core, and the AI workflow becomes the optional
  overlay that feeds proposals into DR's validator rather than writing around it.
  No deprecation.
- **Reminders:** the `ReminderCoordinator` derives every local notification
  from `TimeInterval.reminderMinutesBefore`, `CalendarEvent` popup overrides
  and the explicit `reminder_rules` table (Phase R); legacy fields are not
  duplicated or migrated. Habit reminders (H) plug in as a new `entityType`
  (`'habit'` is reserved) without a schema change. Notification text is still
  Vietnamese-only (legacy residual).

---

## 8. Remaining open questions (not settled by prior approvals)

- ~~**H-a:** does `skipped` pause or break a streak?~~ Settled: pause (H1).
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
