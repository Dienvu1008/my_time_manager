@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/reminder_bridge.dart';
import 'package:my_time_manager/application/reminders/reminder_coordinator.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/application/reminders/reminder_settings.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_habit_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_reminder_rule_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_time_interval_repository.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../application/fake_notification_scheduler.dart';
import 'reminder_wiring_test.dart' show RecordingLegacyScheduler;

/// Phase H3: SqliteHabitRepository → ReminderBridge → ReminderCoordinator
/// with real SQLite (habit edits / outcome records trigger a reconcile).
void main() {
  // Tue Mar 10 2026, 12:00 UTC; horizon 2 days → Mar 10, 11, 12.
  final now = DateTime.utc(2026, 3, 10, 12);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tzdata.initializeTimeZones();
  });

  late FakeNotificationScheduler scheduler;
  late RecordingLegacyScheduler legacy;
  late ReminderBridge bridge;
  late SqliteHabitRepository habits;

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
    scheduler = FakeNotificationScheduler();
    legacy = RecordingLegacyScheduler();
    final coordinator = ReminderCoordinator(
      inputs: RepositoryReminderInputSource(
        timeIntervals: SqliteTimeIntervalRepository(),
        calendar: SqliteCalendarRepository(),
        tasks: SqliteTaskRepository(),
        rules: SqliteReminderRuleRepository(),
        habits: SqliteHabitRepository(),
        now: () => now,
      ),
      scheduler: scheduler,
      location: () => tz.UTC,
      now: () => now,
      config: const ReminderCoordinatorConfig(horizon: Duration(days: 2)),
      habitReminderBody: () => 'Time for your habit',
    );
    bridge = ReminderBridge(
      coordinator: coordinator,
      legacy: legacy,
      legacyToggle: (_) {},
      loadIntervals: SqliteTimeIntervalRepository().getTimeIntervals,
    );
    habits = SqliteHabitRepository(reminderTrigger: bridge);
  });

  int idOf(String habitId, int day, {String time = '1800'}) =>
      stableReminderId('habit:$habitId@202603${day.toString().padLeft(2, '0')}'
          'T$time');

  Habit run({String? time = '18:00'}) => Habit(
        id: 'h',
        title: 'Run',
        startDate: DateTime(2026, 3, 1),
        reminderTime: time,
      );

  test('create schedules each upcoming scheduled day', () async {
    await habits.createHabit(run());
    expect(scheduler.active.keys.toSet(),
        {idOf('h', 10), idOf('h', 11), idOf('h', 12)});
    final r = scheduler.active[idOf('h', 10)]!;
    expect(r.title, 'Run');
    expect(r.body, 'Time for your habit');
    expect(r.fireAt, DateTime.utc(2026, 3, 10, 18));
  });

  test('record / clear outcome reconciles that day', () async {
    await habits.createHabit(run());
    scheduler.clearCalls();

    await habits.recordOutcome('h', DateTime(2026, 3, 10), HabitOutcome.completed);
    expect(scheduler.cancelCalls, [idOf('h', 10)]);
    expect(scheduler.scheduleCalls, isEmpty);
    expect(scheduler.active.containsKey(idOf('h', 10)), isFalse);

    scheduler.clearCalls();
    await habits.clearOutcome('h', DateTime(2026, 3, 10));
    expect(scheduler.scheduleCalls.map((s) => s.id), [idOf('h', 10)]);
    expect(scheduler.cancelCalls, isEmpty);
  });

  test('edit (time change), archive, unarchive and delete reconcile',
      () async {
    await habits.createHabit(run());

    scheduler.clearCalls();
    await habits.updateHabit(run(time: '07:30'));
    // Today 07:30 already passed → 11 and 12 at the new time.
    expect(scheduler.active.keys.toSet(),
        {idOf('h', 11, time: '0730'), idOf('h', 12, time: '0730')});
    expect(scheduler.cancelCalls.toSet(),
        {idOf('h', 10), idOf('h', 11), idOf('h', 12)});

    await habits.archiveHabit('h');
    expect(scheduler.active, isEmpty);

    await habits.unarchiveHabit('h');
    expect(scheduler.active, hasLength(2));

    await habits.deleteHabitPermanently('h');
    expect(scheduler.active, isEmpty);
  });

  test('a second reconcile without changes makes no calls', () async {
    await habits.createHabit(run());
    scheduler.clearCalls();
    await bridge.requestReconcile();
    expect(scheduler.callCount, 0);
  });

  test('legacy mode (coordinator disabled): habit reminders not scheduled',
      () async {
    await bridge.apply(const ReminderSettings(coordinatorEnabled: false));
    scheduler.clearCalls();
    await habits.createHabit(run());
    await habits.recordOutcome('h', DateTime(2026, 3, 11), HabitOutcome.skipped);
    expect(scheduler.callCount, 0);
    expect(scheduler.active, isEmpty);
    // The legacy path only reschedules time intervals.
    expect(legacy.calls, ['rescheduleAll']);
  });
}
