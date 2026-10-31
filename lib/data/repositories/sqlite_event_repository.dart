import '../../domain/repositories/event_repository.dart';
import '../../domain/models/models.dart';
import '../database/database_manager.dart';
import '../database/daos/event_dao.dart';

class SqliteEventRepository implements EventRepository {
  SqliteEventRepository({DatabaseManager? databaseManager})
      : _dao = EventDao(() => (databaseManager ?? DatabaseManager()).database);

  final EventDao _dao;

  @override
  Future<List<Event>> getEventsOfTaskList(String taskListId) => _dao.ofTaskList(taskListId);
}
