import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/reminder_ids.dart';
import 'package:my_time_manager/application/reminders/reminder_text.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/screen_focus_timer/data/notification_service.dart'
    as legacy;

void main() {
  test('legacy interval id equals the NotificationService formula', () {
    for (final m in [0, 15, 1440]) {
      expect(legacyIntervalReminderId('abc', m),
          ('abc#$m').hashCode & 0x7fffffff);
    }
  });

  test('stableReminderId is FNV-1a 32 masked to 31 bits', () {
    expect(stableReminderId(''), 0x811c9dc5 & 0x7fffffff);
    expect(stableReminderId('a'), 0xe40c292c & 0x7fffffff);
    expect(stableReminderId('foobar'), 0xbf9cf968 & 0x7fffffff);
    expect(stableReminderId('rule:x'), stableReminderId('rule:x'));
    expect(stableReminderId('rule:x'), isNot(stableReminderId('rule:y')));
    expect(stableReminderId('rule:x'), greaterThan(0));
  });

  test('key builders and occurrence suffix', () {
    expect(calendarOverrideKey('e1', 10), 'calendarEvent:e1#10');
    expect(
        calendarOverrideKey('e1', 10,
            occurrence: const WallClock(2026, 3, 29, 9, 5)),
        'calendarEvent:e1#10@20260329T0905');
    expect(ruleKey('r1'), 'rule:r1');
    expect(ruleKey('r1', occurrence: const WallClock(2026, 1, 2)),
        'rule:r1@20260102T0000');
  });

  test('candidate helpers', () {
    final ti = TimeInterval(
      id: 'ti',
      startDate: DateTime(2026, 5, 1),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      isEndDateUndefined: true,
      reminderMinutesBefore: [7],
    );
    final ids = legacyCandidateIds(ti);
    expect(ids, contains(legacyIntervalReminderId('ti', 7)));
    for (final m in kCommonReminderMinutes) {
      expect(ids, contains(legacyIntervalReminderId('ti', m)));
    }
    expect(ids.length, kCommonReminderMinutes.length + 1);

    final ev = CalendarEvent(
      id: 'ev',
      title: 'E',
      start: EventDateTime(dateTime: DateTime(2026, 5, 1, 10)),
      end: EventDateTime(dateTime: DateTime(2026, 5, 1, 11)),
      reminders: const EventReminders(useDefault: false, overrides: [
        EventReminderOverride(method: ReminderMethod.popup, minutes: 3),
        EventReminderOverride(method: ReminderMethod.email, minutes: 4),
      ]),
    );
    final evIds = calendarCandidateIds(ev);
    expect(evIds, contains(stableReminderId(calendarOverrideKey('ev', 3))));
    expect(evIds, isNot(contains(stableReminderId(calendarOverrideKey('ev', 4)))));
    expect(evIds.length, kCommonReminderMinutes.length + 1);

    final rule = ReminderRule.offset(
        id: 'r', entityType: ReminderEntityType.task, entityId: 't', minutes: 5);
    expect(ruleCandidateIds(rule), {stableReminderId('rule:r')});
  });

  test('kCommonReminderMinutes is still exported by notification_service', () {
    expect(legacy.kCommonReminderMinutes, kCommonReminderMinutes);
  });

  test('ReminderText keeps the legacy wording', () {
    expect(ReminderText.offsetBody(0, 9, 5), 'Bắt đầu bây giờ (bắt đầu lúc 09:05)');
    expect(ReminderText.offsetBody(2880, 9, 0), 'Còn 2 ngày (bắt đầu lúc 09:00)');
    expect(ReminderText.offsetBody(120, 14, 30), 'Còn 2 giờ (bắt đầu lúc 14:30)');
    expect(ReminderText.offsetBody(15, 8, 0), 'Còn 15 phút (bắt đầu lúc 08:00)');
    expect(ReminderText.absoluteBody(7, 3), 'Nhắc lúc 07:03');
    expect(ReminderText.titleOr(''), 'Sắp đến giờ');
    expect(ReminderText.titleOr('A'), 'A');
  });
}
