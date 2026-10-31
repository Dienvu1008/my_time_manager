import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/notification_scheduler.dart';
import 'package:my_time_manager/application/reminders/reminder_coordinator.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'fake_notification_scheduler.dart';

TimeInterval ti(String id, int hour,
        {List<int> reminders = const [15],
        String title = 'A',
        bool completed = false}) =>
    TimeInterval(
      id: id,
      title: title,
      startDate: DateTime(2026, 5, 1),
      startTime: TimeOfDay(hour: hour, minute: 0),
      isEndDateUndefined: true,
      isCompleted: completed,
      reminderMinutesBefore: reminders,
    );

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late FakeNotificationScheduler scheduler;
  late FakeReminderInputSource source;
  late DateTime now;
  late ReminderCoordinator coordinator;

  ReminderCoordinator build({int maxPending = 64}) => ReminderCoordinator(
        inputs: source,
        scheduler: scheduler,
        location: () => tz.UTC,
        now: () => now,
        config: ReminderCoordinatorConfig(maxPending: maxPending),
      );

  setUp(() {
    scheduler = FakeNotificationScheduler();
    source = FakeReminderInputSource();
    now = DateTime.utc(2026, 4, 30, 12);
    coordinator = build();
  });

  int id(String intervalId, int m) => legacyIntervalReminderId(intervalId, m);

  test('reset twice → active equals desired, each once', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9), ti('b', 10)]);
    await coordinator.reconcileAll();
    await coordinator.reconcileAll();
    expect(scheduler.active.keys.toSet(), {id('a', 15), id('b', 15)});
    expect(scheduler.cancelAllCount, 2);
  });

  test('second incremental reconcile makes 0 calls', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9)]);
    final first = await coordinator.reconcile();
    expect(first.scheduled, 1);
    scheduler.clearCalls();
    final second = await coordinator.reconcile();
    expect(scheduler.callCount, 0);
    expect(second.scheduled, 0);
    expect(second.cancelled, 0);
  });

  test('edited title schedules that id exactly once', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9), ti('b', 10)]);
    await coordinator.reconcileAll();
    scheduler.clearCalls();
    source.inputs =
        ReminderInputs(intervals: [ti('a', 9, title: 'A2'), ti('b', 10)]);
    await coordinator.reconcile();
    expect(scheduler.scheduleCalls.map((r) => r.id), [id('a', 15)]);
    expect(scheduler.cancelCalls, isEmpty);
    expect(scheduler.active[id('a', 15)]!.title, 'A2');
  });

  test('offsets [15,60] → [15] cancels id60 and keeps id15', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9, reminders: [15, 60])]);
    await coordinator.reconcile();
    scheduler.clearCalls();
    source.inputs = ReminderInputs(intervals: [ti('a', 9, reminders: [15])]);
    await coordinator.reconcile();
    expect(scheduler.cancelCalls, [id('a', 60)]);
    expect(scheduler.scheduleCalls, isEmpty);
  });

  test('completed interval is cancelled', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9)]);
    await coordinator.reconcile();
    source.inputs = ReminderInputs(intervals: [ti('a', 9, completed: true)]);
    await coordinator.reconcile();
    expect(scheduler.cancelCalls, [id('a', 15)]);
    expect(scheduler.active, isEmpty);
  });

  test('empty snapshot + alsoCancel issues cancel calls', () async {
    final old = ti('gone', 9);
    final r = await coordinator.reconcile(alsoCancel: legacyCandidateIds(old));
    expect(scheduler.cancelCalls.toSet(), legacyCandidateIds(old));
    expect(r.cancelled, legacyCandidateIds(old).length);
  });

  test('limit deferral and later pickup', () async {
    coordinator = build(maxPending: 2);
    source.inputs = ReminderInputs(intervals: [
      ti('a', 9, reminders: [0]),
      ti('b', 10, reminders: [0]),
      ti('c', 11, reminders: [0]),
    ]);
    final r1 = await coordinator.reconcile();
    expect(r1.scheduled, 2);
    expect(r1.deferred, 1);
    expect(scheduler.active.keys.toSet(), {id('a', 0), id('b', 0)});

    final upcoming = await coordinator.upcoming();
    expect(upcoming.map((u) => u.scheduled), [true, true, false]);
    expect(upcoming.first.fireAtLocal, DateTime(2026, 5, 1, 9));

    scheduler.clearCalls();
    now = DateTime.utc(2026, 5, 1, 9, 30);
    final r2 = await coordinator.reconcile();
    expect(scheduler.scheduleCalls.map((r) => r.id), [id('c', 0)]);
    // 'a' fired at 09:00: dropped from the snapshot, not cancelled (cancel
    // would also dismiss the delivered notification).
    expect(scheduler.cancelCalls, isEmpty);
    expect(r2.deferred, 0);
  });

  test('fired reminder is not cancelled by later incremental runs', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9), ti('b', 10)]);
    await coordinator.reconcile();
    scheduler.clearCalls();
    now = DateTime.utc(2026, 5, 1, 9); // a fired at 08:45, b pending
    await coordinator.reconcile();
    await coordinator.reconcile();
    expect(scheduler.cancelCalls, isEmpty);
    // Explicit alsoCancel (deleted entity) still cancels a fired id.
    await coordinator.reconcile(alsoCancel: [id('a', 15)]);
    expect(scheduler.cancelCalls, [id('a', 15)]);
  });

  test('refreshPermission reports exact alarms not allowed', () async {
    scheduler.exactAllowed = false;
    await coordinator.refreshPermission();
    expect(coordinator.health.value.exactAlarmsAllowed, isFalse);
    await coordinator.requestPermission();
    expect(coordinator.health.value.exactAlarmsAllowed, isTrue);
  });

  test('permission denied → still scheduled, health reports denied', () async {
    scheduler.permission = ReminderPermission.denied;
    source.inputs = ReminderInputs(intervals: [ti('a', 9)]);
    final r = await coordinator.reconcileAll();
    expect(r.scheduled, 1);
    expect(coordinator.health.value.permission, ReminderPermission.denied);
    expect(await coordinator.requestPermission(), isTrue);
    expect(scheduler.requestPermissionCalls, 1);
    expect(coordinator.health.value.permission, ReminderPermission.granted);
  });

  test('throwOnSchedule → no throw, errors counted', () async {
    scheduler.throwOnSchedule = true;
    source.inputs = ReminderInputs(intervals: [ti('a', 9)]);
    final r = await coordinator.reconcile();
    expect(r.errors, greaterThan(0));
    expect(coordinator.health.value.lastError, isNotNull);
    // Failed id is retried on the next run.
    scheduler.throwOnSchedule = false;
    final r2 = await coordinator.reconcile();
    expect(r2.scheduled, 1);
  });

  test('input-load failure keeps the snapshot', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9)]);
    await coordinator.reconcile();
    scheduler.clearCalls();
    source.fail = true;
    final r = await coordinator.reconcile();
    expect(r.errors, 1);
    expect(scheduler.callCount, 0);
    source.fail = false;
    await coordinator.reconcile();
    expect(scheduler.callCount, 0);
    expect(scheduler.active.keys, [id('a', 15)]);
  });

  test('concurrent requests coalesce into one trailing run', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9)]);
    source.gate = Completer<void>();
    final f1 = coordinator.reconcile();
    await Future<void>.delayed(Duration.zero);
    expect(source.loads, 1);
    final f2 = coordinator.reconcile(alsoCancel: [111]);
    final f3 = coordinator.reconcile(alsoCancel: [222]);
    source.gate!.complete();
    final results = await Future.wait([f1, f2, f3]);
    expect(source.loads, 2);
    expect(identical(results[1], results[2]), isTrue);
    expect(scheduler.cancelCalls.toSet(), {111, 222});
  });

  test('disable cancels all and clears the snapshot', () async {
    source.inputs = ReminderInputs(intervals: [ti('a', 9)]);
    await coordinator.reconcile();
    await coordinator.disable();
    expect(scheduler.active, isEmpty);
    scheduler.clearCalls();
    await coordinator.reconcile();
    expect(scheduler.scheduleCalls.map((r) => r.id), [id('a', 15)]);
  });

  test('pendingLimitFor', () {
    expect(pendingLimitFor(TargetPlatform.iOS), 64);
    expect(pendingLimitFor(TargetPlatform.macOS), 64);
    expect(pendingLimitFor(TargetPlatform.android), 400);
    expect(pendingLimitFor(TargetPlatform.windows), 64);
  });
}
