import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app_localizations.dart';

const _locales = [
  'en', 'vi', 'de', 'cs', 'es', 'fr', 'it', 'ja', 'ko', 'no', 'ru', 'sv', 'zh', //
];

/// Every getter added by Phase H3 (reminders, calendar, goal/project links).
Map<String, String Function(AppLocalizations)> _getters = {
  'habitReminderBody': (l) => l.habitReminderBody,
  'habitReminderLabel': (l) => l.habitReminderLabel,
  'habitOpenCheckIn': (l) => l.habitOpenCheckIn,
  'goalLinkHabit': (l) => l.goalLinkHabit,
  'goalHabitsNotCounted': (l) => l.goalHabitsNotCounted,
};

void main() {
  for (final code in _locales) {
    test('every Phase H3 getter resolves for "$code"', () {
      final l = AppLocalizations(Locale(code));
      for (final entry in _getters.entries) {
        expect(entry.value(l).trim(), isNotEmpty,
            reason: '${entry.key} is empty for $code');
      }
    });
  }

  test('non-English locales are translated', () {
    final en = AppLocalizations(const Locale('en'));
    for (final code in _locales.where((c) => c != 'en')) {
      final l = AppLocalizations(Locale(code));
      for (final entry in _getters.entries) {
        expect(entry.value(l), isNot(entry.value(en)),
            reason: '${entry.key} untranslated for $code');
      }
    }
  });
}
