import '../models/model_time_interval.dart';
import '../repositories/time_interval_repository.dart';

/// Domain rules for changing a time interval's completion / measurable progress.
///
/// These rules were previously duplicated inline across several widgets and the
/// calendar data controller (timeline screens, the plan bottom sheet, the
/// per-task interval page). Centralising them here mirrors [TaskCompletionService]
/// for tasks and gives one source of truth that both the UI and a future AI tool
/// can call:
///
///     UI / AI Tool → TimeIntervalProgressService → TimeIntervalRepository → DatabaseManager
///
/// Each method returns the updated [TimeInterval] so callers that keep an
/// in-memory copy (optimistic UI) can refresh their local state. Behaviour is
/// identical to the previous inline `copyWith(...)` + `updateTimeInterval(...)`
/// sequence. Updating persists through the repository, which preserves the
/// reminder-rescheduling side effect of the persistence layer.
class TimeIntervalProgressService {
  TimeIntervalProgressService(this._timeIntervals);

  final TimeIntervalRepository _timeIntervals;

  /// "Started but incomplete" at [now] (pure; used by Daily Review, Phase DR):
  /// not completed, has a known start date AND time at or before [now], and
  /// either a known end after [now] or — when the end is undefined — a start
  /// on [now]'s local day (so ancient open-ended intervals don't stay
  /// "started" forever). A date-only (all-day) start is never "started".
  /// Intervals whose end has already passed are overdue, not started.
  static bool isStartedButIncomplete(TimeInterval interval, DateTime now) {
    if (interval.isCompleted) return false;
    final start = interval.calendarStartDateTime;
    if (interval.isStartDateUndefined ||
        interval.isStartTimeUndefined ||
        start == null) {
      return false;
    }
    if (start.isAfter(now)) return false;
    final end = interval.calendarEndDateTime;
    if (interval.isEndDateUndefined || end == null) {
      return start.year == now.year &&
          start.month == now.month &&
          start.day == now.day;
    }
    return end.isAfter(now);
  }

  /// Toggle a time interval between completed and not-completed.
  Future<TimeInterval> toggleCompleted(TimeInterval interval) async {
    final updated = interval.copyWith(isCompleted: !interval.isCompleted);
    await _timeIntervals.updateTimeInterval(updated);
    return updated;
  }

  /// Update a measurable interval's "how much has been done" progress. Callers
  /// parse user input into [amount] (mirrors the previous inline `double.parse`).
  Future<TimeInterval> updateMeasurableProgress(
      TimeInterval interval, double amount) async {
    final updated = interval.copyWith(howMuchHasBeenDone: amount);
    await _timeIntervals.updateTimeInterval(updated);
    return updated;
  }
}
