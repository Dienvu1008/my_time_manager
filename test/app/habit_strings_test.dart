import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/screen_habits/habit_labels.dart';

const _locales = [
  'en', 'vi', 'de', 'cs', 'es', 'fr', 'it', 'ja', 'ko', 'no', 'ru', 'sv', 'zh', //
];

/// Every getter added by Phase H2 (habit UI).
Map<String, String Function(AppLocalizations)> _getters = {
  'habits': (l) => l.habits,
  'newHabit': (l) => l.newHabit,
  'editHabit': (l) => l.editHabit,
  'noHabitsYet': (l) => l.noHabitsYet,
  'noHabitsHint': (l) => l.noHabitsHint,
  'habitCreateFirst': (l) => l.habitCreateFirst,
  'habitOutcomeCompleted': (l) => l.habitOutcomeCompleted,
  'habitOutcomePartial': (l) => l.habitOutcomePartial,
  'habitOutcomeSkipped': (l) => l.habitOutcomeSkipped,
  'habitOutcomeMissed': (l) => l.habitOutcomeMissed,
  'habitOutcomePending': (l) => l.habitOutcomePending,
  'habitNotScheduledToday': (l) => l.habitNotScheduledToday,
  'habitTodayState': (l) => l.habitTodayState,
  'habitStreakChip': (l) => l.habitStreakChip,
  'habitMarkComplete': (l) => l.habitMarkComplete,
  'habitMarkPartial': (l) => l.habitMarkPartial,
  'habitMarkSkip': (l) => l.habitMarkSkip,
  'habitUndoToday': (l) => l.habitUndoToday,
  'habitTargetAmount': (l) => l.habitTargetAmount,
  'habitTargetInvalid': (l) => l.habitTargetInvalid,
  'habitTargetValue': (l) => l.habitTargetValue,
  'habitPartialCounts': (l) => l.habitPartialCounts,
  'habitEndBeforeStart': (l) => l.habitEndBeforeStart,
  'habitReminderTime': (l) => l.habitReminderTime,
  'habitClearReminderTime': (l) => l.habitClearReminderTime,
  'habitStatistics': (l) => l.habitStatistics,
  'habitCurrentStreak': (l) => l.habitCurrentStreak,
  'habitBestStreak': (l) => l.habitBestStreak,
  'habitCompletionRate': (l) => l.habitCompletionRate,
  'habitRecentHistory': (l) => l.habitRecentHistory,
  'habitNoHistory': (l) => l.habitNoHistory,
  'habitNotRecorded': (l) => l.habitNotRecorded,
  'habitRecordDay': (l) => l.habitRecordDay,
  'habitAmount': (l) => l.habitAmount,
  'habitNote': (l) => l.habitNote,
  'habitClearRecord': (l) => l.habitClearRecord,
  'habitConfirmEditPast': (l) => l.habitConfirmEditPast,
  'habitConfirmChange': (l) => l.habitConfirmChange,
  'confirmArchiveHabit': (l) => l.confirmArchiveHabit,
  'habitDeletePermanently': (l) => l.habitDeletePermanently,
  'confirmDeleteHabitPermanently': (l) => l.confirmDeleteHabitPermanently,
  'habitNotFound': (l) => l.habitNotFound,
  'habitMoreActions': (l) => l.habitMoreActions,
};

void main() {
  for (final code in _locales) {
    test('every Phase H2 getter resolves for "$code"', () {
      final l = AppLocalizations(Locale(code));
      for (final entry in _getters.entries) {
        expect(entry.value(l).trim(), isNotEmpty,
            reason: '${entry.key} is empty for $code');
      }
      expect(l.habitTodayState, contains('{state}'), reason: code);
      expect(l.habitStreakChip, contains('{n}'), reason: code);
      expect(l.habitTargetValue, contains('{value}'), reason: code);
      expect(l.habitConfirmEditPast, contains('{date}'), reason: code);
      // Outcome labels are distinct per locale.
      final labels = {
        for (final o in HabitOutcome.values) habitOutcomeLabel(l, o),
      };
      expect(labels, hasLength(HabitOutcome.values.length), reason: code);
    });
  }

  test('Vietnamese drawer label', () {
    expect(AppLocalizations(const Locale('vi')).habits, 'Thói quen');
  });
}
