import '../../domain/repositories/event_repository.dart';
import '../database/database_manager.dart';
import '../../domain/models/models.dart';

/// SQLite-backed [EventRepository] for the legacy `events` table.
class SqliteEventRepository implements EventRepository {
  SqliteEventRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<Event>> getEventsOfTaskList(String taskListId) =>
      _db.eventsOfTaskList(taskListId);
}
