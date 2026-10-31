import '../../domain/repositories/trash_repository.dart';
import '../../screen_trash/model_trashed_item.dart';
import '../database/daos/calendar_event_dao.dart';
import '../database/daos/goal_dao.dart';
import '../database/daos/project_dao.dart';
import '../database/daos/task_dao.dart';
import '../database/daos/task_list_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [TrashRepository].
///
/// Per-item restore/delete goes through the aggregate DAOs (which preserve the
/// soft-delete cascade and restore-by-timestamp semantics). Cross-table queries
/// (listing, emptying, purging the trash) stay in [DatabaseManager].
class SqliteTrashRepository implements TrashRepository {
  SqliteTrashRepository({DatabaseManager? databaseManager})
      : this._(databaseManager ?? DatabaseManager());

  SqliteTrashRepository._(DatabaseManager db)
      : _db = db,
        _taskLists = TaskListDao(() => db.database),
        _tasks = TaskDao(() => db.database),
        _calendarEvents = CalendarEventDao(() => db.database),
        _goals = GoalDao(() => db.database),
        _projects = ProjectDao(() => db.database);

  final DatabaseManager _db;
  final TaskListDao _taskLists;
  final TaskDao _tasks;
  final CalendarEventDao _calendarEvents;
  final GoalDao _goals;
  final ProjectDao _projects;

  @override
  Future<List<TrashedItem>> getTrashedItems() => _db.trashedItems();

  @override
  Future<void> restore(TrashedItem item) {
    switch (item.type) {
      case TrashedItemType.taskList:
        return _taskLists.restore(item.id);
      case TrashedItemType.task:
        return _tasks.restore(item.id);
      case TrashedItemType.calendarEvent:
        return _calendarEvents.restore(item.id);
      case TrashedItemType.goal:
        return _goals.restore(item.id);
      case TrashedItemType.project:
        return _projects.restore(item.id);
    }
  }

  @override
  Future<void> permanentlyDelete(TrashedItem item) {
    switch (item.type) {
      case TrashedItemType.taskList:
        return _taskLists.permanentlyDelete(item.id);
      case TrashedItemType.task:
        return _tasks.permanentlyDelete(item.id);
      case TrashedItemType.calendarEvent:
        return _calendarEvents.delete(item.id);
      case TrashedItemType.goal:
        return _goals.permanentlyDelete(item.id);
      case TrashedItemType.project:
        return _projects.permanentlyDelete(item.id);
    }
  }

  @override
  Future<void> emptyTrash() => _db.emptyTrash();

  @override
  Future<int> purgeExpiredTrash(int retentionDays) =>
      _db.purgeExpiredTrash(retentionDays);
}
