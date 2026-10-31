import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/screen_reminders/reminder_labels.dart';

const _locales = [
  'en', 'vi', 'de', 'cs', 'es', 'fr', 'it', 'ja', 'ko', 'no', 'ru', 'sv', 'zh', //
];

Map<String, String Function(AppLocalizations)> _getters = {
  'reminders': (l) => l.reminders,
  'upcomingReminders': (l) => l.upcomingReminders,
  'noUpcomingReminders': (l) => l.noUpcomingReminders,
  'noUpcomingRemindersHint': (l) => l.noUpcomingRemindersHint,
  'reminderDeferred': (l) => l.reminderDeferred,
  'reminderShiftedQuietHours': (l) => l.reminderShiftedQuietHours,
  'reminderHighPriority': (l) => l.reminderHighPriority,
  'notificationsDenied': (l) => l.notificationsDenied,
  'allowNotifications': (l) => l.allowNotifications,
  'exactAlarmsDenied': (l) => l.exactAlarmsDenied,
  'remindersOffInfo': (l) => l.remindersOffInfo,
  'reminderRulesSaveFailed': (l) => l.reminderRulesSaveFailed,
  'quietHours': (l) => l.quietHours,
  'quietHoursSubtitle': (l) => l.quietHoursSubtitle,
  'quietHoursStart': (l) => l.quietHoursStart,
  'quietHoursEnd': (l) => l.quietHoursEnd,
  'reminderEngine': (l) => l.reminderEngine,
  'reminderEngineSubtitle': (l) => l.reminderEngineSubtitle,
  'reminderLegacyModeInfo': (l) => l.reminderLegacyModeInfo,
  'reminderAdd': (l) => l.reminderAdd,
  'reminderEdit': (l) => l.reminderEdit,
  'reminderDelete': (l) => l.reminderDelete,
  'reminderNone': (l) => l.reminderNone,
  'reminderPickTitle': (l) => l.reminderPickTitle,
  'reminderCustomMinutes': (l) => l.reminderCustomMinutes,
  'reminderCustomMinutesTitle': (l) => l.reminderCustomMinutesTitle,
  'reminderCustomMinutesHint': (l) => l.reminderCustomMinutesHint,
  'reminderConfirmAdd': (l) => l.reminderConfirmAdd,
  'reminderCancel': (l) => l.reminderCancel,
  'reminderAtStart': (l) => l.reminderAtStart,
  'reminderOneMinuteBefore': (l) => l.reminderOneMinuteBefore,
  'reminderMinutesBefore': (l) => l.reminderMinutesBefore,
  'reminderOneHourBefore': (l) => l.reminderOneHourBefore,
  'reminderHoursBefore': (l) => l.reminderHoursBefore,
  'reminderOneDayBefore': (l) => l.reminderOneDayBefore,
  'reminderDaysBefore': (l) => l.reminderDaysBefore,
  'reminderOneWeekBefore': (l) => l.reminderOneWeekBefore,
  'reminderWeeksBefore': (l) => l.reminderWeeksBefore,
  'reminderAtSpecificTime': (l) => l.reminderAtSpecificTime,
  'reminderAbsoluteAt': (l) => l.reminderAbsoluteAt,
  'useCalendarDefault': (l) => l.useCalendarDefault,
  'useCalendarDefaultSubtitle': (l) => l.useCalendarDefaultSubtitle,
};

void main() {
  for (final code in _locales) {
    test('every Phase R getter resolves for "$code"', () {
      final l = AppLocalizations(Locale(code));
      for (final entry in _getters.entries) {
        expect(entry.value(l).trim(), isNotEmpty,
            reason: '${entry.key} is empty for $code');
      }
      for (final key in [
        'reminderMinutesBefore',
        'reminderHoursBefore',
        'reminderDaysBefore',
        'reminderWeeksBefore',
      ]) {
        expect(_getters[key]!(l), contains('{n}'), reason: '$key/$code');
      }
      expect(l.reminderAbsoluteAt, contains('{time}'));
    });
  }

  test('Vietnamese offset labels match the legacy AlarmListTile text', () {
    final vi = AppLocalizations(const Locale('vi'));
    const expected = {
      0: 'Đúng giờ',
      5: '5 phút trước',
      10: '10 phút trước',
      15: '15 phút trước',
      30: '30 phút trước',
      60: '1 giờ trước',
      120: '2 giờ trước',
      1440: '1 ngày trước',
      2880: '2 ngày trước',
      10080: '1 tuần trước',
      45: '45 phút trước',
      180: '3 giờ trước',
    };
    expected.forEach((minutes, label) {
      expect(reminderOffsetLabel(vi, minutes), label);
    });
  });

  test('English offset labels use singular/plural', () {
    final en = AppLocalizations(const Locale('en'));
    expect(reminderOffsetLabel(en, 0), 'At start time');
    expect(reminderOffsetLabel(en, 1), '1 minute before');
    expect(reminderOffsetLabel(en, 45), '45 minutes before');
    expect(reminderOffsetLabel(en, 60), '1 hour before');
    expect(reminderOffsetLabel(en, 2880), '2 days before');
    expect(reminderOffsetLabel(en, 20160), '2 weeks before');
  });
}
