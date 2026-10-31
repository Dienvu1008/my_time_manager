import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminder_scheduler.dart';
import 'package:my_time_manager/application/reminders/quiet_hours.dart';
import 'package:my_time_manager/application/reminders/reminder_bridge.dart';
import 'package:my_time_manager/application/reminders/reminder_coordinator.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/application/reminders/reminder_settings.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'fake_notification_scheduler.dart';

class FakeLegacyScheduler implements ReminderScheduler {
  final List<String> calls = [];
  List<TimeInterval>? rescheduled;

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
  Future<void> rescheduleAll(List<TimeInterval> intervals) async {
    calls.add('rescheduleAll');
    rescheduled = intervals;
  }
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late FakeNotificationScheduler scheduler;
  late FakeReminderInputSource source;
  late FakeLegacyScheduler legacy;
  late List<bool> toggles;
  late ReminderBridge bridge;
  final interval = TimeInterval(
    id: 'a',
    title: 'A',
    startDate: DateTime(2026, 5, 1),
    startTime: const TimeOfDay(hour: 9, minute: 0),
    isEndDateUndefined: true,
    reminderMinutesBefore: [15],
  );

  setUp(() {
    scheduler = FakeNotificationScheduler();
    source = FakeReminderInputSource(ReminderInputs(intervals: [interval]));
    legacy = FakeLegacyScheduler();
    toggles = [];
    bridge = ReminderBridge(
      coordinator: ReminderCoordinator(
        inputs: source,
        scheduler: scheduler,
        location: () => tz.UTC,
        now: () => DateTime.utc(2026, 4, 30, 12),
      ),
      legacy: legacy,
      legacyToggle: toggles.add,
      loadIntervals: () async => [interval],
    );
  });

  test('default coordinator mode: hooks reconcile, legacy untouched', () async {
    await bridge.schedule(interval);
    expect(scheduler.active.keys, [legacyIntervalReminderId('a', 15)]);
    // Simulate deletion: the interval is gone from the inputs.
    source.inputs = const ReminderInputs();
    await bridge.cancel(interval);
    expect(scheduler.cancelCalls.toSet(), legacyCandidateIds(interval));
    expect(scheduler.active, isEmpty);
    await bridge.requestReconcile(alsoCancel: [42]);
    expect(scheduler.cancelCalls, contains(42));
    expect(legacy.calls, isEmpty);
  });

  test('scheduleAll reconciles once for the whole batch', () async {
    await bridge.scheduleAll([interval, interval, interval]);
    expect(source.loads, 1);
    expect(scheduler.active.keys, [legacyIntervalReminderId('a', 15)]);
    await bridge.apply(const ReminderSettings(coordinatorEnabled: false));
    await bridge.scheduleAll([interval]);
    expect(legacy.calls.last, 'scheduleAll:1');
  });

  test('apply enabled + coordinator → quiet hours set and reset reconcile',
      () async {
    const quiet = QuietHours(enabled: true, startMinutes: 60, endMinutes: 120);
    await bridge.apply(const ReminderSettings(quietHours: quiet));
    expect(toggles, [true]);
    expect(bridge.coordinator.quietHours, quiet);
    expect(scheduler.cancelAllCount, 1);
    expect(scheduler.active.keys, [legacyIntervalReminderId('a', 15)]);
  });

  test('flag off → legacy delegated and trigger is a no-op', () async {
    await bridge.apply(const ReminderSettings(coordinatorEnabled: false));
    expect(legacy.calls, ['rescheduleAll']);
    expect(legacy.rescheduled, [interval]);
    await bridge.schedule(interval);
    await bridge.cancel(interval);
    await bridge.rescheduleAll([interval]);
    await bridge.requestReconcile(alsoCancel: [1]);
    expect(legacy.calls,
        ['rescheduleAll', 'schedule:a', 'cancel:a', 'rescheduleAll']);
    expect(scheduler.callCount, 0);
  });

  test('disabled → coordinator.disable + legacyToggle(false), hooks no-op',
      () async {
    await bridge.schedule(interval);
    await bridge.apply(const ReminderSettings(enabled: false));
    expect(toggles, [false]);
    expect(scheduler.cancelAllCount, 1);
    expect(scheduler.active, isEmpty);
    scheduler.clearCalls();
    await bridge.schedule(interval);
    await bridge.requestReconcile();
    expect(scheduler.callCount, 0);
    expect(legacy.calls, isEmpty);
  });

  test('flag on → off deactivates the coordinator and reschedules legacy',
      () async {
    await bridge.apply(const ReminderSettings());
    scheduler.clearCalls();
    await bridge.apply(const ReminderSettings(coordinatorEnabled: false));
    expect(scheduler.callCount, 0);
    expect(legacy.calls, ['rescheduleAll']);
    expect(toggles, [true, true]);
  });
}
