import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/planned_reminder.dart';
import 'package:my_time_manager/application/reminders/quiet_hours.dart';
import 'package:my_time_manager/application/reminders/reminder_coordinator.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/application/reminders/reminder_planner.dart';
import 'package:my_time_manager/application/reminders/reminder_text.dart';
import 'package:my_time_manager/application/reminders/wall_clock_resolver.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/reminder_rule_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../shared/fake_repositories.dart' show FakeHabitRepository;
import 'fake_notification_scheduler.dart';

/// Phase H3: habit reminders derived by the R planner / coordinator.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  // Tue Mar 10 2026, 12:00 UTC.
  final now = DateTime.utc(2026, 3, 10, 12);
  final planner = ReminderPlanner(location: tz.UTC);
  const twoDays = Duration(days: 2);

  Habit habit(String id,
          {String? time = '18:00',
          DateTime? start,
          DateTime? end,
          RepeatRule? rule}) =>
      Habit(
        id: id,
        title: 'Habit $id',
        startDate: start ?? DateTime(2026, 3, 1),
        endDate: end,
        reminderTime: time,
        recurrence: rule,
      );

  Habit archived(Habit h) => Habit.fromMap({
        ...h.toMap(),
        'isArchived': 1,
        'archivedAt': DateTime(2026, 3, 20).toIso8601String(),
      });

  HabitOccurrence rec(String habitId, int day, HabitOutcome o) =>
      HabitOccurrence(
          habitId: habitId, localDate: DateTime(2026, 3, day), outcome: o);

  List<PlannedReminder> plan(ReminderInputs inputs,
          {QuietHours quiet = QuietHours.off,
          Duration horizon = twoDays,
          ReminderPlanner? with_,
          DateTime? at}) =>
      (with_ ?? planner)
          .plan(inputs, now: at ?? now, quietHours: quiet, horizon: horizon);

  test('scheduled day with reminderTime → one reminder, deterministic id', () {
    final out = plan(ReminderInputs(habits: [habit('h')]));
    expect(out.map((r) => r.fireAt), [
      DateTime.utc(2026, 3, 10, 18),
      DateTime.utc(2026, 3, 11, 18),
      DateTime.utc(2026, 3, 12, 18),
    ]);
    final first = out.first;
    expect(first.key, 'habit:h@20260310T1800');
    expect(first.id, stableReminderId('habit:h@20260310T1800'));
    expect(first.id, stableReminderId(habitReminderKey(
        'h', const WallClock(2026, 3, 10, 18, 0))));
    expect(first.entityType, ReminderEntityType.habit);
    expect(first.entityId, 'h');
    expect(first.title, 'Habit h');
    expect(first.body, ReminderText.habitBody);
    expect(first.source, ReminderSource.habit);
    expect(first.anchorAt, isNull);
    // Same inputs → same output (ids stable across runs).
    expect(plan(ReminderInputs(habits: [habit('h')])), out);
  });

  test("today's time already passed → starts tomorrow", () {
    final out = plan(ReminderInputs(habits: [habit('h', time: '07:00')]));
    expect(out.first.fireAt, DateTime.utc(2026, 3, 11, 7));
    expect(out, hasLength(2));
  });

  test('recorded day (any resolved outcome) is suppressed; pending is not',
      () {
    for (final o in [
      HabitOutcome.completed,
      HabitOutcome.partial,
      HabitOutcome.skipped,
      HabitOutcome.missed,
    ]) {
      final out = plan(ReminderInputs(
          habits: [habit('h')], habitOccurrences: [rec('h', 11, o)]));
      expect(out.map((r) => r.fireAt.day), [10, 12], reason: o.name);
    }
    final pending = plan(ReminderInputs(
        habits: [habit('h')],
        habitOccurrences: [rec('h', 11, HabitOutcome.pending)]));
    expect(pending, hasLength(3));
    // Rows of another habit do not suppress.
    final other = plan(ReminderInputs(
        habits: [habit('h')],
        habitOccurrences: [rec('x', 11, HabitOutcome.completed)]));
    expect(other, hasLength(3));
  });

  test('archived / ended / no reminder time → none', () {
    expect(plan(ReminderInputs(habits: [archived(habit('a'))])), isEmpty);
    expect(
        plan(ReminderInputs(habits: [habit('e', end: DateTime(2026, 3, 9))])),
        isEmpty);
    expect(plan(ReminderInputs(habits: [habit('n', time: null)])), isEmpty);
    // endDate inside the horizon bounds the days.
    final bounded =
        plan(ReminderInputs(habits: [habit('b', end: DateTime(2026, 3, 11))]));
    expect(bounded.map((r) => r.fireAt.day), [10, 11]);
  });

  test('only days scheduled by the current rule (and ≥ startDate)', () {
    final weekly = habit('w',
        rule: const RepeatRule(
            frequency: RepeatFrequency.weekly, weekdays: {DateTime.wednesday}),
        start: DateTime(2026, 3, 4));
    final out = plan(ReminderInputs(habits: [weekly]),
        horizon: const Duration(days: 14));
    expect(out.map((r) => r.fireAt.day), [11, 18]);
    final late = plan(ReminderInputs(habits: [habit('l', start: DateTime(2026, 3, 12))]));
    expect(late.map((r) => r.fireAt.day), [12]);
  });

  test('quiet hours are applied by the shared planner path', () {
    const quiet = QuietHours(enabled: true, startMinutes: 22 * 60, endMinutes: 7 * 60);
    final out = plan(ReminderInputs(habits: [habit('q', time: '23:00')]),
        quiet: quiet, horizon: Duration.zero);
    expect(out.single.fireAt, DateTime.utc(2026, 3, 11, 7));
    expect(out.single.shiftedByQuietHours, isTrue);
    expect(out.single.id, stableReminderId('habit:q@20260310T2300'));
  });

  test('DST gap: wall-clock resolution delegated to resolveWallClock', () {
    final ny = tz.getLocation('America/New_York');
    final p = ReminderPlanner(location: ny);
    // 2026-03-08 02:30 does not exist in New York (spring forward).
    final out = p.plan(ReminderInputs(habits: [habit('d', time: '02:30')]),
        now: DateTime.utc(2026, 3, 7, 12), horizon: const Duration(days: 1));
    expect(out.single.fireAt,
        resolveWallClock(ny, const WallClock(2026, 3, 8, 2, 30)));
    expect(out.single.fireAt, DateTime.utc(2026, 3, 8, 7));
    expect(out.single.key, 'habit:d@20260308T0230');
  });

  test('localized body comes from the planner configuration', () {
    final p = ReminderPlanner(
        location: tz.UTC, habitReminderBody: 'Time for your habit');
    final out = plan(ReminderInputs(habits: [habit('h')]), with_: p);
    expect(out.every((r) => r.body == 'Time for your habit'), isTrue);
  });

  group('coordinator', () {
    late FakeNotificationScheduler scheduler;
    late FakeReminderInputSource source;
    late ReminderCoordinator coordinator;

    setUp(() {
      scheduler = FakeNotificationScheduler();
      source = FakeReminderInputSource(ReminderInputs(habits: [habit('h')]));
      coordinator = ReminderCoordinator(
        inputs: source,
        scheduler: scheduler,
        location: () => tz.UTC,
        now: () => now,
        config: const ReminderCoordinatorConfig(horizon: twoDays),
        habitReminderBody: () => 'Localized',
      );
    });

    test('reconcile is idempotent; recording a day cancels its reminder',
        () async {
      await coordinator.reconcile();
      expect(scheduler.scheduleCalls, hasLength(3));
      expect(scheduler.scheduleCalls.first.body, 'Localized');
      scheduler.clearCalls();

      await coordinator.reconcile();
      expect(scheduler.callCount, 0);

      source.inputs = ReminderInputs(
          habits: [habit('h')],
          habitOccurrences: [rec('h', 11, HabitOutcome.completed)]);
      await coordinator.reconcile();
      expect(scheduler.scheduleCalls, isEmpty);
      expect(scheduler.cancelCalls,
          [stableReminderId('habit:h@20260311T1800')]);
    });

    test('pending-limit selection applies to habit reminders', () async {
      final limited = ReminderCoordinator(
        inputs: source,
        scheduler: scheduler,
        location: () => tz.UTC,
        now: () => now,
        config:
            const ReminderCoordinatorConfig(maxPending: 2, horizon: twoDays),
      );
      final r = await limited.reconcile();
      expect(scheduler.active, hasLength(2));
      expect(r.deferred, 1);
      final upcoming = await limited.upcoming();
      expect(upcoming, hasLength(3));
      expect(upcoming.where((u) => !u.scheduled), hasLength(1));
      expect(upcoming.every((u) => u.planned.entityType == 'habit'), isTrue);
    });
  });

  test('RepositoryReminderInputSource loads active habits with a time',
      () async {
    final repo = FakeHabitRepository();
    await repo.createHabit(habit('h'));
    await repo.createHabit(habit('n', time: null));
    await repo.createHabit(habit('a'));
    await repo.archiveHabit('a');
    await repo.recordOutcome('h', DateTime(2026, 3, 11), HabitOutcome.skipped);
    await repo.recordOutcome('h', DateTime(2026, 3, 1), HabitOutcome.skipped);
    final source = RepositoryReminderInputSource(
      timeIntervals: _EmptyIntervals(),
      calendar: _EmptyCalendar(),
      tasks: _EmptyTasks(),
      rules: _EmptyRules(),
      habits: repo,
      now: () => DateTime(2026, 3, 10, 12),
    );
    final inputs = await source.load();
    expect(inputs.habits.map((h) => h.id), ['h']);
    expect(inputs.habitOccurrences.map((o) => o.localDate.day), [11]);
  });
}

/// Empty stand-in for the R repositories (only the list getters are called).
class _EmptyIntervals implements TimeIntervalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(<Never>[]);
}

class _EmptyCalendar implements CalendarRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(<Never>[]);
}

class _EmptyTasks implements TaskRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(<Never>[]);
}

class _EmptyRules implements ReminderRuleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(<Never>[]);
}
