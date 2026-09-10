import 'package:uuid/uuid.dart';

import '../../data/models/model_time_interval.dart';
import '../repositories/time_interval_repository.dart';
import 'repeat_rule.dart';

/// Expands a repeating time interval into concrete occurrences and persists
/// them. This rule previously lived inside a bottom-sheet widget
/// (`_saveWithRepeat`); centralising it here means both the UI and a future AI
/// tool can create recurring schedules the same way:
///
///     UI / AI Tool → RecurrenceService → TimeIntervalRepository → DatabaseManager
///
/// Approach (unchanged from the original): a repeating interval is modelled as
/// MANY independent [TimeInterval]s, one per generated start date. Each keeps
/// the original time-of-day and the original start→end date span, and gets a
/// fresh id.
class RecurrenceService {
  RecurrenceService(this._timeIntervals, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final TimeIntervalRepository _timeIntervals;
  final Uuid _uuid;

  /// Persist [base] according to [rule]. Returns the number of occurrences
  /// created. [onProgress] is invoked after each save with (done, total).
  Future<int> saveWithRepeat(
    TimeInterval base,
    RepeatRule rule, {
    void Function(int done, int total)? onProgress,
  }) async {
    // Not repeating, or no start date to anchor on -> save exactly one.
    if (!rule.isRepeating || base.startDate == null) {
      await _timeIntervals.createTimeInterval(base);
      onProgress?.call(1, 1);
      return 1;
    }

    final startDates = rule.generateStartDates(base.startDate!);
    final total = startDates.length;

    // Keep the end-date offset constant so each occurrence has the same length.
    Duration? endOffset;
    if (base.endDate != null) {
      final s = DateTime(
          base.startDate!.year, base.startDate!.month, base.startDate!.day);
      final e =
          DateTime(base.endDate!.year, base.endDate!.month, base.endDate!.day);
      endOffset = e.difference(s);
    }

    var count = 0;
    for (final date in startDates) {
      final newStart = DateTime(
        date.year,
        date.month,
        date.day,
        base.startTime?.hour ?? 0,
        base.startTime?.minute ?? 0,
      );
      final newEnd = endOffset != null
          ? DateTime(date.year, date.month, date.day).add(endOffset)
          : base.endDate;

      final occurrence = base.copyWith(
        startDate: DateTime(newStart.year, newStart.month, newStart.day),
        endDate: newEnd,
      );
      // Fresh id per occurrence so they do not overwrite each other.
      occurrence.id = _uuid.v4();

      await _timeIntervals.createTimeInterval(occurrence);
      count++;
      onProgress?.call(count, total);
    }
    return count;
  }
}
