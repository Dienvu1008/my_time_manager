import '../../domain/repositories/task_repository.dart';
import '../../domain/models/model_task.dart';
import '../database/database_manager.dart';
import '../database/daos/task_dao.dart';

class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository({DatabaseManager? databaseManager})
      : _dao = TaskDao(() => (databaseManager ?? DatabaseManager()).database);

  final TaskDao _dao;

  @override
  Future<List<Task>> getTasks() => _dao.getAll();

  @override
  Future<Task> getTask(String id) => _dao.getById(id);

  @override
  Future<List<Task>> getTasksOfTaskList(String taskListId) => _dao.ofTaskList(taskListId);

  @override
  Future<List<Task>> getTasksWithoutTaskList() => _dao.withoutTaskList();

  @override
  Future<void> createTask(Task task) => _dao.insert(task);

  @override
  Future<void> updateTask(Task task) => _dao.update(task);

  @override
  Future<void> moveTask(String taskId, String? newTaskListId) => _dao.move(taskId, newTaskListId);

  @override
  Future<void> deleteTask(String id) => _dao.delete(id);

  @override
  Future<void> softDeleteTask(String id) => _dao.softDelete(id);

  @override
  Future<void> restoreTask(String id) => _dao.restore(id);

  @override
  Future<void> permanentlyDeleteTask(String id) => _dao.permanentlyDelete(id);

  @override
  Future<void> archiveTask(String id) => _dao.archive(id);

  @override
  Future<void> unarchiveTask(String id) => _dao.unarchive(id);
}
