import '../../domain/repositories/task_list_repository.dart';
import '../../domain/models/model_list.dart';
import '../database/database_manager.dart';
import '../database/daos/task_list_dao.dart';

class SqliteTaskListRepository implements TaskListRepository {
  SqliteTaskListRepository({DatabaseManager? databaseManager})
      : _dao = TaskListDao(() => (databaseManager ?? DatabaseManager()).database);

  final TaskListDao _dao;

  @override
  Future<List<TaskList>> getTaskLists() => _dao.getAll();

  @override
  Future<TaskList> getTaskList(String id) => _dao.getById(id);

  @override
  Future<void> createTaskList(TaskList taskList) => _dao.insert(taskList);

  @override
  Future<void> updateTaskList(TaskList taskList) => _dao.update(taskList);

  @override
  Future<void> deleteTaskList(String id) => _dao.delete(id);

  @override
  Future<void> softDeleteTaskList(String id) => _dao.softDelete(id);

  @override
  Future<void> restoreTaskList(String id) => _dao.restore(id);

  @override
  Future<void> permanentlyDeleteTaskList(String id) => _dao.permanentlyDelete(id);

  @override
  Future<void> archiveTaskList(String id) => _dao.archive(id);

  @override
  Future<void> unarchiveTaskList(String id) => _dao.unarchive(id);
}
