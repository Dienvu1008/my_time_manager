import '../models/model_time_interval.dart';

/// Domain boundary for **time intervals** (planned schedule entries for a task
/// or one of its subtasks).
///
/// Callers (UI, blocs, controllers, and — in the future — AI tools) depend on
/// this interface, never on [DatabaseManager] / SQLite directly.
///
/// NOTE on side effects: creating/updating a time interval schedules its
/// notification reminders, and deleting one cancels them. These side effects
/// are coordinated by the injected ReminderScheduler (in the app: the
/// ReminderBridge, which forwards to the ReminderCoordinator or, with the
/// feature flag off, to the legacy notification path). Callers should not
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

  /// Create many time intervals (e.g. the occurrences of a repeating one),
  /// then schedule their reminders in one batch. [onProgress] is invoked
  /// after each insert with the number created so far. Not all-or-nothing:
  /// if an insert fails, the intervals inserted before it are kept and their
  /// reminders are still scheduled, then the error is rethrown.
  Future<void> createTimeIntervals(
    List<TimeInterval> timeIntervals, {
    void Function(int done)? onProgress,
  });

  /// Update a time interval (also reschedules its reminders).
  Future<void> updateTimeInterval(TimeInterval timeInterval);

  /// Delete a time interval (also cancels its reminders).
  Future<void> deleteTimeInterval(String id);

  /// Reschedule all reminders from persisted intervals. Used when the user
  /// re-enables reminders (all were cancelled when disabled). Safe no-op when
  /// reminders are disabled.
  Future<void> rescheduleAllReminders();
}
