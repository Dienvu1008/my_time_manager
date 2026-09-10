import '../../data/models/model_time_interval.dart';
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
