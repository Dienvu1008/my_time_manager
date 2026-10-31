import '../../application/reminder_scheduler.dart';
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/time_interval_repository.dart';
import '../database/database_manager.dart';
import '../database/daos/time_interval_dao.dart';

/// SQLite-backed [TimeIntervalRepository].
///
/// Thin adapter: [TimeIntervalDao] (pure SQL) + [ReminderScheduler]
/// (notification side-effect). The DAO was extracted from DatabaseManager
/// in Core Track C4.
class SqliteTimeIntervalRepository implements TimeIntervalRepository {
  SqliteTimeIntervalRepository({
    DatabaseManager? databaseManager,
    ReminderScheduler? reminderScheduler,
  })  : _dao = TimeIntervalDao(() => (databaseManager ?? DatabaseManager()).database),
        _reminders = reminderScheduler ?? const NoOpReminderScheduler();

  final TimeIntervalDao _dao;
  final ReminderScheduler _reminders;

  @override
  Future<List<TimeInterval>> getTimeIntervals() => _dao.getAll();

  @override
  Future<TimeInterval> getTimeInterval(String id) => _dao.getById(id);

  @override
  Future<List<TimeInterval>> getTimeIntervalsOfTask(String taskId) => _dao.ofTask(taskId);

  @override
  Future<List<TimeInterval>> getAllTimeIntervalsOfTask(String taskId) => _dao.allOfTask(taskId);

  @override
  Future<List<TimeInterval>> getTimeIntervalsOfSubtask(String subtaskId) =>
      _dao.ofSubtask(subtaskId);

  @override
  Future<void> createTimeInterval(TimeInterval timeInterval) async {
    await _dao.insert(timeInterval);
    await _reminders.schedule(timeInterval);
  }

  @override
  Future<void> updateTimeInterval(TimeInterval timeInterval) async {
    await _dao.update(timeInterval);
    await _reminders.schedule(timeInterval);
  }

  @override
  Future<void> deleteTimeInterval(String id) async {
    TimeInterval? ti;
    try {
      ti = await _dao.getById(id);
    } catch (_) {}
    await _dao.delete(id);
    if (ti != null) await _reminders.cancel(ti);
  }

  @override
  Future<void> rescheduleAllReminders() async {
    final all = await _dao.getAll();
    await _reminders.rescheduleAll(all);
  }
}
