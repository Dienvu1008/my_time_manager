import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app_localizations.dart';

/// Phase DR2 strings: every getter is non-empty in all 13 locales.
void main() {
  const codes = [
    'en', 'vi', 'de', 'cs', 'es', 'fr', 'it', 'ja', 'ko', 'no', 'ru', 'sv',
    'zh', //
  ];

  for (final code in codes) {
    test('Daily Review strings present for $code', () {
      final l = AppLocalizations(Locale(code));
      final values = <String>[
        l.dailyReview,
        l.dailyReviewEmpty,
        l.dailyReviewSectionOverdue,
        l.dailyReviewSectionStarted,
        l.dailyReviewSectionDueToday,
        l.dailyReviewSectionHabits,
        l.dailyReviewSectionUnscheduled,
        l.dailyReviewFreeTime,
        l.dailyReviewActionDoNow,
        l.dailyReviewActionReschedule,
        l.dailyReviewActionSplit,
        l.dailyReviewActionKeepPending,
        l.dailyReviewActionCancel,
        l.dailyReviewPreview,
        l.dailyReviewApply,
        l.dailyReviewConfirmTitle,
        l.dailyReviewNothingToApply,
        l.dailyReviewPartialResult,
        l.dailyReviewDurationHint,
        l.dailyReviewDeadlineBadge,
        l.dailyReviewStatusApplied,
        l.dailyReviewStatusStale,
        l.dailyReviewStatusConflict,
        l.dailyReviewStatusFailed,
        l.dailyReviewDeadlineWillMove,
        l.dailyReviewNotificationTitle,
        l.dailyReviewNotificationBody,
        l.dailyReviewSettings,
        l.dailyReviewEnable,
        l.dailyReviewTime,
        l.dailyReviewWorkingHoursStart,
        l.dailyReviewWorkingHoursEnd,
        l.dailyReviewBufferMinutes,
        l.dailyReviewWorkingDays,
        l.dailyReviewHabitOpenDetail,
        l.dailyReviewNoTime,
        l.dailyReviewWorkload,
        l.dailyReviewTargetDay,
        l.dailyReviewFirstPart,
        l.dailyReviewSecondPart,
        l.dailyReviewNoAction,
        l.dailyReviewConfirmSummary,
        l.dailyReviewDeleteWarning,
        l.dailyReviewStatusNoChange,
        l.dailyReviewStatusNeedsDuration,
        l.dailyReviewStatusNoCapacity,
        l.dailyReviewStatusUnresolvable,
        l.dailyReviewStatusNotApplicable,
        l.dailyReviewImportantBadge,
        l.dailyReviewExactTime,
        l.dailyReviewResults,
      ];
      for (final v in values) {
        expect(v.trim(), isNotEmpty);
      }
      for (final p in ['{moves}', '{creates}', '{deletes}']) {
        expect(l.dailyReviewConfirmSummary, contains(p));
      }
    });
  }
}
