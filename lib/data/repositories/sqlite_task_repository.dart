import '../../application/reminders/reminder_reconcile_trigger.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/models/model_task.dart';
import '../database/database_manager.dart';
import '../database/daos/task_dao.dart';

/// SQLite-backed [TaskRepository]. Mutations that can change reminders
/// (title/importance synced into intervals, task-rule suppression) ask the
/// injected [ReminderReconcileTrigger] (Phase R) to reconcile.
class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository({
    DatabaseManager? databaseManager,
    ReminderReconcileTrigger? reminderTrigger,
  })  : _dao = TaskDao(() => (databaseManager ?? DatabaseManager()).database),
        _trigger = reminderTrigger ?? const NoOpReminderReconcileTrigger();

  final TaskDao _dao;
  final ReminderReconcileTrigger _trigger;

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
  Future<void> updateTask(Task task) async {
    await _dao.update(task);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> moveTask(String taskId, String? newTaskListId) => _dao.move(taskId, newTaskListId);

  @override
  Future<void> deleteTask(String id) async {
    await _dao.delete(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> softDeleteTask(String id) async {
    await _dao.softDelete(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> restoreTask(String id) async {
    await _dao.restore(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> permanentlyDeleteTask(String id) async {
    await _dao.permanentlyDelete(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> archiveTask(String id) async {
    await _dao.archive(id);
    await _trigger.requestReconcile();
  }

  @override
  Future<void> unarchiveTask(String id) async {
    await _dao.unarchive(id);
    await _trigger.requestReconcile();
  }
}
