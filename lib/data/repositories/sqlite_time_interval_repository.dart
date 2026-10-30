import '../../application/reminder_scheduler.dart';
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/time_interval_repository.dart';
import '../database/database_manager.dart';

/// SQLite-backed [TimeIntervalRepository].
///
/// Thin adapter over [DatabaseManager] (pure SQL). Reminder side-effects are
/// coordinated here via an injected [ReminderScheduler], so that
/// [DatabaseManager] remains a platform-agnostic SQL layer (fixes H3).
///
/// Production: inject [NotificationReminderScheduler].
/// Tests / desktop: inject [NoOpReminderScheduler] (no Flutter binding needed).
class SqliteTimeIntervalRepository implements TimeIntervalRepository {
  SqliteTimeIntervalRepository({
    DatabaseManager? databaseManager,
    ReminderScheduler? reminderScheduler,
  })  : _db = databaseManager ?? DatabaseManager(),
        _reminders = reminderScheduler ?? const NoOpReminderScheduler();

  final DatabaseManager _db;
  final ReminderScheduler _reminders;

  @override
  Future<List<TimeInterval>> getTimeIntervals() => _db.timeIntervals();

  @override
  Future<TimeInterval> getTimeInterval(String id) => _db.timeInterval(id);

  @override
  Future<List<TimeInterval>> getTimeIntervalsOfTask(String taskId) =>
      _db.timeIntervalsOfTask(taskId);

  @override
  Future<List<TimeInterval>> getAllTimeIntervalsOfTask(String taskId) =>
      _db.allTimeIntervalsOfTask(taskId);

  @override
  Future<List<TimeInterval>> getTimeIntervalsOfSubtask(String subtaskId) =>
      _db.timeIntervalsOfSubtask(subtaskId);

  @override
  Future<void> createTimeInterval(TimeInterval timeInterval) async {
    await _db.insertTimeInterval(timeInterval);
    await _reminders.schedule(timeInterval);
  }

  @override
  Future<void> updateTimeInterval(TimeInterval timeInterval) async {
    await _db.updateTimeInterval(timeInterval);
    // schedule() tự hủy mốc cũ rồi đặt lại (NotificationService đã làm vậy).
    await _reminders.schedule(timeInterval);
  }

  @override
  Future<void> deleteTimeInterval(String id) async {
    // Cần đọc interval trước khi xóa để hủy đúng các mốc nhắc đã đặt.
    TimeInterval? ti;
    try {
      ti = await _db.timeInterval(id);
    } catch (_) {
      // Không tìm thấy interval → không có gì để hủy.
    }
    await _db.deleteTimeInterval(id);
    if (ti != null) await _reminders.cancel(ti);
  }

  @override
  Future<void> rescheduleAllReminders() async {
    final all = await _db.timeIntervals();
    await _reminders.rescheduleAll(all);
  }
}
