import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/planned_reminder.dart';
import 'package:my_time_manager/application/reminders/quiet_hours.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/application/reminders/reminder_planner.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Phase DR2: the daily-review notification derived by the R planner.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  // Tue Mar 10 2026, 12:00 UTC.
  final now = DateTime.utc(2026, 3, 10, 12);
  final planner = ReminderPlanner(location: tz.UTC);

  ReminderInputs inputs({int time = 20 * 60, int horizon = 2}) =>
      ReminderInputs(
        dailyReviewNotification: DailyReviewNotificationInputs(
          reviewTimeMinutes: time,
          horizonDays: horizon,
          title: 'Daily review',
          body: 'Review your day',
        ),
      );

  List<PlannedReminder> dr(List<PlannedReminder> all) => [
        for (final p in all)
          if (p.entityType == ReminderEntityType.dailyReview) p
      ];

  test('disabled (no input) → no notification', () {
    expect(dr(planner.plan(const ReminderInputs(), now: now)), isEmpty);
  });

  test('one notification per day at the review time, deterministic ids', () {
    final out = dr(planner.plan(inputs(), now: now));
    expect(out.map((p) => p.fireAt), [
      DateTime.utc(2026, 3, 10, 20),
      DateTime.utc(2026, 3, 11, 20),
      DateTime.utc(2026, 3, 12, 20),
    ]);
    expect(out.first.id,
        stableReminderId(dailyReviewReminderKey(DateTime(2026, 3, 10))));
    expect(out.first.key, 'dailyReview@20260310');
    expect(out.map((p) => p.source), everyElement(ReminderSource.dailyReview));
    expect(out.first.title, 'Daily review');
    expect(out.first.body, 'Review your day');
    expect(out.map((p) => p.id).toSet().length, 3, reason: 'distinct per day');
  });

  test('a review time already passed today is not scheduled for today', () {
    final out = dr(planner.plan(inputs(time: 9 * 60), now: now));
    expect(out.first.fireAt, DateTime.utc(2026, 3, 11, 9));
  });

  test('ids depend on the day, not the time (time change reuses ids)', () {
    final a = dr(planner.plan(inputs(time: 20 * 60), now: now));
    final b = dr(planner.plan(inputs(time: 21 * 60), now: now));
    expect(a.map((p) => p.id), b.map((p) => p.id));
    expect(b.first.fireAt, DateTime.utc(2026, 3, 10, 21));
  });

  test('idempotent: planning twice gives identical output', () {
    final a = dr(planner.plan(inputs(), now: now));
    final b = dr(planner.plan(inputs(), now: now));
    expect(a.map((p) => '${p.id}@${p.fireAt}'),
        b.map((p) => '${p.id}@${p.fireAt}'));
  });

  test('quiet hours are applied by the shared planner step', () {
    final out = dr(planner.plan(inputs(time: 23 * 60), now: now,
        quietHours: const QuietHours(
            enabled: true, startMinutes: 22 * 60, endMinutes: 7 * 60)));
    expect(out.first.fireAt, DateTime.utc(2026, 3, 11, 7));
    expect(out.first.shiftedByQuietHours, isTrue);
  });
}
