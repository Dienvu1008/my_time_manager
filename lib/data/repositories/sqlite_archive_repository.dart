import '../../domain/repositories/archive_repository.dart';
import '../../screen_archive/model_archived_item.dart';
import '../database/daos/calendar_event_dao.dart';
import '../database/daos/goal_dao.dart';
import '../database/daos/habit_dao.dart';
import '../database/daos/learning_dao.dart';
import '../database/daos/project_dao.dart';
import '../database/daos/task_dao.dart';
import '../database/daos/task_list_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [ArchiveRepository].
///
/// Per-item unarchive/trash goes through the aggregate DAOs (which preserve the
/// archive cascade and unarchive-by-timestamp semantics). The cross-table
/// listing query stays in [DatabaseManager].
class SqliteArchiveRepository implements ArchiveRepository {
  SqliteArchiveRepository({DatabaseManager? databaseManager})
      : this._(databaseManager ?? DatabaseManager());

  SqliteArchiveRepository._(DatabaseManager db)
      : _db = db,
        _taskLists = TaskListDao(() => db.database),
        _tasks = TaskDao(() => db.database),
        _calendarEvents = CalendarEventDao(() => db.database),
        _goals = GoalDao(() => db.database),
        _projects = ProjectDao(() => db.database),
        _learning = LearningDao(() => db.database),
        _habits = HabitDao(() => db.database);

  final DatabaseManager _db;
  final TaskListDao _taskLists;
  final TaskDao _tasks;
  final CalendarEventDao _calendarEvents;
  final GoalDao _goals;
  final ProjectDao _projects;
  final LearningDao _learning;
  final HabitDao _habits;

  @override
  Future<List<ArchivedItem>> getArchivedItems() => _db.archivedItems();

  @override
  Future<void> unarchive(ArchivedItem item) {
    switch (item.type) {
      case ArchivedItemType.taskList:
        return _taskLists.unarchive(item.id);
      case ArchivedItemType.task:
        return _tasks.unarchive(item.id);
      case ArchivedItemType.calendarEvent:
        return _calendarEvents.unarchive(item.id);
      case ArchivedItemType.goal:
        return _goals.unarchive(item.id);
      case ArchivedItemType.project:
        return _projects.unarchive(item.id);
      case ArchivedItemType.course:
        return _learning.unarchive(item.id);
      case ArchivedItemType.habit:
        return _habits.unarchive(item.id);
    }
  }

  @override
  Future<void> moveToTrash(ArchivedItem item) async {
    // Unarchive first, then soft-delete, so the item shows correctly in trash.
    switch (item.type) {
      case ArchivedItemType.taskList:
        await _taskLists.unarchive(item.id);
        await _taskLists.softDelete(item.id);
        break;
      case ArchivedItemType.task:
        await _tasks.unarchive(item.id);
        await _tasks.softDelete(item.id);
        break;
      case ArchivedItemType.calendarEvent:
        await _calendarEvents.unarchive(item.id);
        await _calendarEvents.softDelete(item.id);
        break;
      case ArchivedItemType.goal:
        await _goals.unarchive(item.id);
        await _goals.softDelete(item.id);
        break;
      case ArchivedItemType.project:
        await _projects.unarchive(item.id);
        await _projects.softDelete(item.id);
        break;
      case ArchivedItemType.course:
        await _learning.unarchive(item.id);
        await _learning.softDelete(item.id);
        break;
      case ArchivedItemType.habit:
        // Habits have no trash (archive is their default removal; hard delete
        // is an explicit HabitRepository operation).
        throw UnsupportedError('Habits cannot be moved to trash');
    }
  }
}
