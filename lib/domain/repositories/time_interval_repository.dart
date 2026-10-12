import '../models/model_time_interval.dart';

/// Domain boundary for **time intervals** (planned schedule entries for a task
/// or one of its subtasks).
///
/// Callers (UI, blocs, controllers, and — in the future — AI tools) depend on
/// this interface, never on [DatabaseManager] / SQLite directly.
///
/// NOTE on side effects: creating/updating a time interval schedules its
/// notification reminders, and deleting one cancels them. That behaviour lives
/// inside the existing persistence layer and is preserved exactly by the SQLite
/// implementation (which delegates 1:1 to DatabaseManager). Callers should not
/// assume these are pure data operations.
abstract class TimeIntervalRepository {
  /// All time intervals.
  Future<List<TimeInterval>> getTimeIntervals();

  /// A single time interval by id.
  Future<TimeInterval> getTimeInterval(String id);

  /// Intervals planned for the task itself (excludes its subtasks' intervals).
  Future<List<TimeInterval>> getTimeIntervalsOfTask(String taskId);

  /// All intervals of a task, including those of its subtasks.
  Future<List<TimeInterval>> getAllTimeIntervalsOfTask(String taskId);

  /// Intervals planned for one specific subtask.
  Future<List<TimeInterval>> getTimeIntervalsOfSubtask(String subtaskId);

  /// Create a time interval (also schedules its reminders).
  Future<void> createTimeInterval(TimeInterval timeInterval);

  /// Update a time interval (also reschedules its reminders).
  Future<void> updateTimeInterval(TimeInterval timeInterval);

  /// Delete a time interval (also cancels its reminders).
  Future<void> deleteTimeInterval(String id);

  /// Reschedule all reminders from persisted intervals. Used when the user
  /// re-enables reminders (all were cancelled when disabled). Safe no-op when
  /// reminders are disabled.
  Future<void> rescheduleAllReminders();
}
