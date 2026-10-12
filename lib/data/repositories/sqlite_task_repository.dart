import '../../domain/repositories/task_repository.dart';
import '../database/database_manager.dart';
import '../../domain/models/model_task.dart';

/// SQLite-backed [TaskRepository].
///
/// Thin adapter over the existing [DatabaseManager] singleton. It intentionally
/// contains **no** new persistence logic — it delegates 1:1 to the battle-tested
/// [DatabaseManager] so schema, migrations, triggers, and reminder side effects
/// are preserved exactly.
class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<Task>> getTasks() => _db.tasks();

  @override
  Future<Task> getTask(String id) => _db.task(id);

  @override
  Future<List<Task>> getTasksOfTaskList(String taskListId) =>
      _db.tasksOfTaskList(taskListId);

  @override
  Future<List<Task>> getTasksWithoutTaskList() => _db.tasksWithoutTaskList();

  @override
  Future<void> createTask(Task task) => _db.insertTask(task);

  @override
  Future<void> updateTask(Task task) => _db.updateTask(task);

  @override
  Future<void> moveTask(String taskId, String? newTaskListId) =>
      _db.moveTask(taskId, newTaskListId);

  @override
  Future<void> deleteTask(String id) => _db.deleteTask(id);

  @override
  Future<void> softDeleteTask(String id) => _db.softDeleteTask(id);

  @override
  Future<void> restoreTask(String id) => _db.restoreTask(id);

  @override
  Future<void> permanentlyDeleteTask(String id) =>
      _db.permanentlyDeleteTask(id);

  @override
  Future<void> archiveTask(String id) => _db.archiveTask(id);

  @override
  Future<void> unarchiveTask(String id) => _db.unarchiveTask(id);
}
