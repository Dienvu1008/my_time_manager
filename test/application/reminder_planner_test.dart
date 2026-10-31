import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/planned_reminder.dart';
import 'package:my_time_manager/application/reminders/quiet_hours.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/application/reminders/reminder_planner.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

TimeInterval interval(String id, int hour, int minute,
        {List<int> reminders = const [15],
        bool completed = false,
        bool important = false,
        String title = 'Interval'}) =>
    TimeInterval(
      id: id,
      title: title,
      startDate: DateTime(2026, 5, 1),
      startTime: TimeOfDay(hour: hour, minute: minute),
      isEndDateUndefined: true,
      isCompleted: completed,
      isImportant: important,
      reminderMinutesBefore: reminders,
    );

CalendarEvent event(String id,
        {DateTime? start,
        EventReminders reminders = const EventReminders(
            useDefault: false,
            overrides: [
              EventReminderOverride(method: ReminderMethod.popup, minutes: 10),
              EventReminderOverride(method: ReminderMethod.email, minutes: 30),
            ]),
        EventStatus status = EventStatus.confirmed,
        List<String> recurrence = const []}) {
  final s = start ?? DateTime(2026, 5, 1, 10);
  return CalendarEvent(
    id: id,
    title: 'Event',
    start: EventDateTime(dateTime: s),
    end: EventDateTime(dateTime: s.add(const Duration(hours: 1))),
    reminders: reminders,
    status: status,
    recurrence: recurrence,
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final now = DateTime.utc(2026, 4, 30, 12);
  final planner = ReminderPlanner(location: tz.UTC);

  List<PlannedReminder> plan(ReminderInputs inputs,
          {QuietHours quiet = QuietHours.off, DateTime? at}) =>
      planner.plan(inputs, now: at ?? now, quietHours: quiet);

  test('legacy interval id and fireAt match NotificationService', () {
    final out = plan(ReminderInputs(intervals: [interval('ti1', 9, 0)]));
    expect(out, hasLength(1));
    final r = out.single;
    expect(r.id, ('ti1#15').hashCode & 0x7fffffff);
    expect(r.anchorAt, DateTime.utc(2026, 5, 1, 9));
    expect(r.fireAt, DateTime.utc(2026, 5, 1, 9).subtract(const Duration(minutes: 15)));
    expect(r.title, 'Interval');
    expect(r.body, 'Còn 15 phút (bắt đầu lúc 09:00)');
    expect(r.source, ReminderSource.legacy);
  });

  test('important interval → high priority; empty title → fallback', () {
    final r = plan(ReminderInputs(
            intervals: [interval('ti1', 9, 0, important: true, title: '')]))
        .single;
    expect(r.priority, ReminderPriority.high);
    expect(r.title, 'Sắp đến giờ');
  });

  test('completed interval → no reminder', () {
    expect(plan(ReminderInputs(intervals: [interval('ti1', 9, 0, completed: true)])),
        isEmpty);
  });

  test('past fireAt is dropped', () {
    final out = plan(ReminderInputs(intervals: [interval('ti1', 9, 0)]),
        at: DateTime.utc(2026, 5, 1, 8, 45));
    expect(out, isEmpty);
  });

  test('calendar: popup overrides only, useDefault → none, cancelled → none', () {
    final out = plan(ReminderInputs(events: [event('ev1')]));
    expect(out, hasLength(1));
    expect(out.single.id, stableReminderId(calendarOverrideKey('ev1', 10)));
    expect(out.single.fireAt, DateTime.utc(2026, 5, 1, 9, 50));

    expect(
        plan(ReminderInputs(events: [
          event('ev2', reminders: const EventReminders(useDefault: true))
        ])),
        isEmpty);
    expect(
        plan(ReminderInputs(
            events: [event('ev3', status: EventStatus.cancelled)])),
        isEmpty);
  });

  test('UTC calendar dateTime is an absolute instant', () {
    final berlinPlanner =
        ReminderPlanner(location: tz.getLocation('Europe/Berlin'));
    final out = berlinPlanner.plan(
        ReminderInputs(
            events: [event('ev1', start: DateTime.utc(2026, 5, 1, 10))]),
        now: now);
    expect(out.single.fireAt, DateTime.utc(2026, 5, 1, 9, 50));
    // Body shows Berlin wall-clock (CEST, +2).
    expect(out.single.body, 'Còn 10 phút (bắt đầu lúc 12:00)');
  });

  test('recurring daily 09:00 across Berlin DST resolves per occurrence', () {
    final berlinPlanner = ReminderPlanner(
      location: tz.getLocation('Europe/Berlin'),
      expandOccurrences: (e, from, to) =>
          [DateTime(2026, 3, 28, 9), DateTime(2026, 3, 29, 9)],
    );
    final out = berlinPlanner.plan(
      ReminderInputs(events: [
        event('rec',
            start: DateTime(2026, 3, 28, 9),
            recurrence: const ['RRULE:FREQ=DAILY'],
            reminders: const EventReminders(useDefault: false, overrides: [
              EventReminderOverride(method: ReminderMethod.popup, minutes: 0),
            ])),
      ]),
      now: DateTime.utc(2026, 3, 27),
    );
    expect(out.map((r) => r.fireAt),
        [DateTime.utc(2026, 3, 28, 8), DateTime.utc(2026, 3, 29, 7)]);
    expect(out[0].id,
        stableReminderId(calendarOverrideKey('rec', 0,
            occurrence: const WallClock(2026, 3, 28, 9))));
    expect(out[0].id, isNot(out[1].id));
  });

  test('absolute task rule; suppressed when task completed or absent', () {
    final rule = ReminderRule.absolute(
        id: 'r1',
        entityType: ReminderEntityType.task,
        entityId: 't1',
        at: const WallClock(2026, 5, 2, 8, 30));
    final task = Task(id: 't1', title: 'Task');
    final out = plan(ReminderInputs(tasks: [task], rules: [rule]));
    expect(out.single.id, stableReminderId('rule:r1'));
    expect(out.single.fireAt, DateTime.utc(2026, 5, 2, 8, 30));
    expect(out.single.body, 'Nhắc lúc 08:30');
    expect(out.single.title, 'Task');

    expect(
        plan(ReminderInputs(
            tasks: [Task(id: 't1', title: 'Task', isCompleted: true)],
            rules: [rule])),
        isEmpty);
    expect(plan(ReminderInputs(rules: [rule])), isEmpty);
  });

  test('offset rule on task, disabled rule and unknown type are skipped', () {
    final task = Task(id: 't1', title: 'Task');
    final out = plan(ReminderInputs(tasks: [
      task
    ], intervals: [
      interval('ti1', 9, 0, reminders: const [])
    ], rules: [
      ReminderRule.offset(
          entityType: ReminderEntityType.task, entityId: 't1', minutes: 5),
      ReminderRule.offset(
          entityType: ReminderEntityType.timeInterval,
          entityId: 'ti1',
          minutes: 5,
          enabled: false),
      ReminderRule.absolute(
          entityType: 'habit',
          entityId: 'h1',
          at: const WallClock(2026, 5, 2, 8)),
    ]));
    expect(out, isEmpty);
  });

  test('explicit offset rule on interval is merged', () {
    final out = plan(ReminderInputs(intervals: [
      interval('ti1', 9, 0)
    ], rules: [
      ReminderRule.offset(
          id: 'r5',
          entityType: ReminderEntityType.timeInterval,
          entityId: 'ti1',
          minutes: 60),
    ]));
    expect(out.map((r) => r.id),
        [stableReminderId('rule:r5'), legacyIntervalReminderId('ti1', 15)]);
    expect(out.first.source, ReminderSource.rule);
  });

  test('same-fireAt dedupe: tie keeps legacy, higher priority wins', () {
    ReminderRule r(ReminderPriority p) => ReminderRule.offset(
        id: 'dup',
        entityType: ReminderEntityType.timeInterval,
        entityId: 'ti1',
        minutes: 15,
        priority: p);
    final tie = plan(ReminderInputs(
        intervals: [interval('ti1', 9, 0)], rules: [r(ReminderPriority.normal)]));
    expect(tie.single.source, ReminderSource.legacy);

    final high = plan(ReminderInputs(
        intervals: [interval('ti1', 9, 0)], rules: [r(ReminderPriority.high)]));
    expect(high.single.source, ReminderSource.rule);
  });

  test('quiet hours: shift kept before anchor, suppressed past anchor', () {
    const quiet = QuietHours(enabled: true, startMinutes: 1320, endMinutes: 420);
    final out = plan(
      ReminderInputs(intervals: [
        interval('keep', 7, 5), // 06:50 → 07:00 (before 07:05)
        interval('drop', 6, 30, reminders: const [60]), // 05:30 → 07:00 > 06:30
      ], tasks: [
        Task(id: 't1', title: 'T')
      ], rules: [
        ReminderRule.absolute(
            id: 'abs',
            entityType: ReminderEntityType.task,
            entityId: 't1',
            at: const WallClock(2026, 5, 1, 23, 0)),
      ]),
      quiet: quiet,
    );
    expect(out.map((r) => r.id),
        [legacyIntervalReminderId('keep', 15), stableReminderId('rule:abs')]);
    expect(out[0].fireAt, DateTime.utc(2026, 5, 1, 7));
    expect(out[0].shiftedByQuietHours, isTrue);
    expect(out[1].fireAt, DateTime.utc(2026, 5, 2, 7));
    expect(out[1].shiftedByQuietHours, isTrue);
  });

  test('output is sorted by fireAt', () {
    final out = plan(ReminderInputs(intervals: [
      interval('b', 11, 0),
      interval('a', 9, 0),
      interval('c', 10, 0),
    ]));
    expect(out.map((r) => r.entityId), ['a', 'c', 'b']);
  });
}
