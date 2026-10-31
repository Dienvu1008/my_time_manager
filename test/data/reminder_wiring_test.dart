@TestOn('vm')
library;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminder_scheduler.dart';
import 'package:my_time_manager/application/reminders/reminder_bridge.dart';
import 'package:my_time_manager/application/reminders/reminder_coordinator.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/application/reminders/reminder_settings.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_reminder_rule_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_time_interval_repository.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../application/fake_notification_scheduler.dart';

/// Legacy C3 scheduler fake: records calls only.
class RecordingLegacyScheduler implements ReminderScheduler {
  final List<String> calls = [];

  @override
  Future<void> schedule(TimeInterval interval) async =>
      calls.add('schedule:${interval.id}');
  @override
  Future<void> scheduleAll(List<TimeInterval> intervals) async =>
      calls.add('scheduleAll:${intervals.length}');
  @override
  Future<void> cancel(TimeInterval interval) async =>
      calls.add('cancel:${interval.id}');
  @override
  Future<void> rescheduleAll(List<TimeInterval> intervals) async =>
      calls.add('rescheduleAll');
}

/// Real SQLite repositories wired through ReminderBridge -> ReminderCoordinator
/// (Phase R, plan item 5 Verify).
void main() {
  final now = DateTime.utc(2026, 4, 30, 12);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tzdata.initializeTimeZones();
  });

  late FakeNotificationScheduler scheduler;
  late RecordingLegacyScheduler legacy;
  late ReminderBridge bridge;
  late SqliteTimeIntervalRepository intervals;
  late SqliteCalendarRepository calendar;
  late SqliteTaskRepository tasks;
  late SqliteReminderRuleRepository rules;

  /// Builds a fresh coordinator + bridge (empty snapshot) and wires the
  /// repositories to it. Inputs come from hook-less repositories.
  void wire() {
    final coordinator = ReminderCoordinator(
      inputs: RepositoryReminderInputSource(
        timeIntervals: SqliteTimeIntervalRepository(),
        calendar: SqliteCalendarRepository(),
        tasks: SqliteTaskRepository(),
        rules: SqliteReminderRuleRepository(),
      ),
      scheduler: scheduler,
      location: () => tz.UTC,
      now: () => now,
    );
    bridge = ReminderBridge(
      coordinator: coordinator,
      legacy: legacy,
      legacyToggle: (_) {},
      loadIntervals: SqliteTimeIntervalRepository().getTimeIntervals,
    );
    intervals = SqliteTimeIntervalRepository(reminderScheduler: bridge);
    calendar = SqliteCalendarRepository(reminderTrigger: bridge);
    tasks = SqliteTaskRepository(reminderTrigger: bridge);
    rules = SqliteReminderRuleRepository(reminderTrigger: bridge);
  }

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
    scheduler = FakeNotificationScheduler();
    legacy = RecordingLegacyScheduler();
    wire();
  });

  Future<Task> seedTask([String title = 'Owner']) async {
    final task = Task(title: title);
    await SqliteTaskRepository().createTask(task);
    return task;
  }

  TimeInterval interval(String taskId, {String title = 'Study'}) =>
      TimeInterval(
        taskId: taskId,
        title: title,
        startDate: DateTime(2026, 5, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        isEndDateUndefined: true,
        reminderMinutesBefore: [15],
      );

  CalendarEvent event(String id) => CalendarEvent(
        id: id,
        title: 'Meeting',
        start: EventDateTime(dateTime: DateTime(2026, 5, 1, 10)),
        end: EventDateTime(dateTime: DateTime(2026, 5, 1, 11)),
        reminders: const EventReminders(useDefault: false, overrides: [
          EventReminderOverride(method: ReminderMethod.popup, minutes: 10),
        ]),
      );

  test('time interval: create schedules legacy id, edit once, complete cancels',
      () async {
    final task = await seedTask();
    final ti = interval(task.id);
    final id = legacyIntervalReminderId(ti.id, 15);

    await intervals.createTimeInterval(ti);
    expect(scheduler.active.keys, [id]);
    expect(scheduler.active[id]!.fireAt, DateTime.utc(2026, 5, 1, 8, 45));

    scheduler.clearCalls();
    await intervals.updateTimeInterval(ti.copyWith(title: 'Study ML'));
    expect(scheduler.scheduleCalls.map((r) => r.id), [id]);
    expect(scheduler.active[id]!.title, 'Study ML');

    scheduler.clearCalls();
    await intervals.updateTimeInterval(
        ti.copyWith(title: 'Study ML', isCompleted: true));
    expect(scheduler.cancelCalls, contains(id));
    expect(scheduler.scheduleCalls, isEmpty);
    expect(scheduler.active, isEmpty);
  });

  test('createTimeIntervals persists all and schedules every reminder',
      () async {
    final task = await seedTask();
    final batch = [
      interval(task.id, title: 'A'),
      interval(task.id, title: 'B'),
      interval(task.id, title: 'C'),
    ];
    final progress = <int>[];
    await intervals.createTimeIntervals(batch, onProgress: progress.add);
    expect(progress, [1, 2, 3]);
    expect((await intervals.getTimeIntervals()).length, 3);
    expect(scheduler.active.keys.toSet(),
        {for (final ti in batch) legacyIntervalReminderId(ti.id, 15)});
  });

  test('time interval: delete cancels (also via alsoCancel on a fresh engine)',
      () async {
    final task = await seedTask();
    final a = interval(task.id, title: 'A');
    final b = interval(task.id, title: 'B');
    await intervals.createTimeInterval(a);
    await intervals.createTimeInterval(b);
    final idA = legacyIntervalReminderId(a.id, 15);
    final idB = legacyIntervalReminderId(b.id, 15);
    expect(scheduler.active.keys, containsAll([idA, idB]));

    await intervals.deleteTimeInterval(a.id);
    expect(scheduler.cancelCalls, contains(idA));
    expect(scheduler.active.keys, [idB]);

    // Fresh coordinator: empty snapshot, cancellation comes from alsoCancel.
    wire();
    scheduler.clearCalls();
    await intervals.deleteTimeInterval(b.id);
    expect(scheduler.cancelCalls, contains(idB));
    expect(scheduler.active, isEmpty);
  });

  test('calendar popup override scheduled; soft-delete cancels', () async {
    final ev = event('ev1');
    final id = stableReminderId(calendarOverrideKey('ev1', 10));

    await calendar.createCalendarEvent(ev);
    expect(scheduler.active.keys, [id]);
    expect(scheduler.active[id]!.fireAt, DateTime.utc(2026, 5, 1, 9, 50));

    scheduler.clearCalls();
    await calendar.softDeleteCalendarEvent('ev1');
    expect(scheduler.cancelCalls, contains(id));
    expect(scheduler.active, isEmpty);
  });

  test('absolute task rule scheduled; completing the task cancels', () async {
    final task = await seedTask('Pay bills');
    final rule = ReminderRule.absolute(
      entityType: ReminderEntityType.task,
      entityId: task.id,
      at: const WallClock(2026, 5, 2, 8, 30),
    );
    final id = ruleCandidateIds(rule).single;

    await rules.saveRule(rule);
    expect(scheduler.active.keys, [id]);
    expect(scheduler.active[id]!.fireAt, DateTime.utc(2026, 5, 2, 8, 30));

    scheduler.clearCalls();
    await tasks.updateTask(task.copyWith(isCompleted: true));
    expect(scheduler.cancelCalls, contains(id));
    expect(scheduler.active, isEmpty);
  });

  test('deleteRule cancels via alsoCancel on a fresh engine', () async {
    final task = await seedTask();
    final rule = ReminderRule.absolute(
      entityType: ReminderEntityType.task,
      entityId: task.id,
      at: const WallClock(2026, 5, 2, 8, 30),
    );
    await rules.saveRule(rule);
    final id = ruleCandidateIds(rule).single;

    wire();
    scheduler.clearCalls();
    await rules.deleteRule(rule.id);
    expect(scheduler.cancelCalls, contains(id));
    expect(scheduler.active, isEmpty);
  });

  test('flag off: calendar/rules not scheduled, legacy receives intervals',
      () async {
    await bridge.apply(const ReminderSettings(coordinatorEnabled: false));
    expect(legacy.calls, ['rescheduleAll']);

    final task = await seedTask();
    final ti = interval(task.id);
    await intervals.createTimeInterval(ti);
    await calendar.createCalendarEvent(event('ev1'));
    await rules.saveRule(ReminderRule.absolute(
      entityType: ReminderEntityType.task,
      entityId: task.id,
      at: const WallClock(2026, 5, 2, 8, 30),
    ));

    expect(legacy.calls, ['rescheduleAll', 'schedule:${ti.id}']);
    expect(scheduler.scheduleCalls, isEmpty);
    expect(scheduler.active, isEmpty);
  });
}
