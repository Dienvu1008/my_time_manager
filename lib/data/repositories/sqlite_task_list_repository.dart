import '../../domain/repositories/task_list_repository.dart';
import '../database/database_manager.dart';
import '../models/model_list.dart';

/// SQLite-backed [TaskListRepository].
///
/// Thin adapter over the existing [DatabaseManager] singleton. It intentionally
/// contains **no** new persistence logic — it delegates 1:1 to the battle-tested
/// [DatabaseManager] so schema, migrations, triggers, and cascade semantics are
/// preserved exactly.
class SqliteTaskListRepository implements TaskListRepository {
  SqliteTaskListRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<TaskList>> getTaskLists() => _db.taskLists();

  @override
  Future<TaskList> getTaskList(String id) => _db.taskList(id);

  @override
  Future<void> createTaskList(TaskList taskList) => _db.insertTaskList(taskList);

  @override
  Future<void> updateTaskList(TaskList taskList) => _db.updateTaskList(taskList);

  @override
  Future<void> deleteTaskList(String id) => _db.deleteTaskList(id);

  @override
  Future<void> softDeleteTaskList(String id) => _db.softDeleteTaskList(id);

  @override
  Future<void> restoreTaskList(String id) => _db.restoreTaskList(id);

  @override
  Future<void> permanentlyDeleteTaskList(String id) =>
      _db.permanentlyDeleteTaskList(id);

  @override
  Future<void> archiveTaskList(String id) => _db.archiveTaskList(id);

  @override
  Future<void> unarchiveTaskList(String id) => _db.unarchiveTaskList(id);
}
