import '../../domain/repositories/time_interval_repository.dart';
import '../database/database_manager.dart';
import '../../domain/models/model_time_interval.dart';

/// SQLite-backed [TimeIntervalRepository].
///
/// Thin adapter over the existing [DatabaseManager] singleton. It delegates 1:1
/// so the reminder-scheduling side effects that DatabaseManager performs on
/// insert/update/delete are preserved exactly.
class SqliteTimeIntervalRepository implements TimeIntervalRepository {
  SqliteTimeIntervalRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

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
  Future<void> createTimeInterval(TimeInterval timeInterval) =>
      _db.insertTimeInterval(timeInterval);

  @override
  Future<void> updateTimeInterval(TimeInterval timeInterval) =>
      _db.updateTimeInterval(timeInterval);

  @override
  Future<void> deleteTimeInterval(String id) => _db.deleteTimeInterval(id);

  @override
  Future<void> rescheduleAllReminders() => _db.rescheduleAllReminders();
}
