import '../models/model_task.dart';

/// Domain boundary for **tasks** (the unified [Task] model, which covers plain,
/// measurable, and with-subtasks tasks).
///
/// Callers (UI, blocs, controllers, and — in the future — AI tools) depend on
/// this interface, never on [DatabaseManager] / SQLite directly. Implementations
/// live in `lib/data/repositories/` and adapt to the existing persistence layer.
///
/// Trash (soft-delete) and archive are modelled here as *capabilities of the
/// task domain* rather than as separate repositories.
abstract class TaskRepository {
  /// All visible tasks (excludes trashed and archived).
  Future<List<Task>> getTasks();

  /// A single task by id.
  Future<Task> getTask(String id);

  /// Visible tasks belonging to a given list.
  Future<List<Task>> getTasksOfTaskList(String taskListId);

  /// Visible "loose" tasks that do not belong to any list.
  Future<List<Task>> getTasksWithoutTaskList();

  /// Create a new task.
  Future<void> createTask(Task task);

  /// Update an existing task.
  Future<void> updateTask(Task task);

  /// Move a task to another list (null = detach to top level).
  Future<void> moveTask(String taskId, String? newTaskListId);

  /// Hard-delete a task. Prefer [softDeleteTask] for user-facing deletes.
  Future<void> deleteTask(String id);

  // --- Trash (soft-delete) ---

  /// Move a task to trash.
  Future<void> softDeleteTask(String id);

  /// Restore a task from trash.
  Future<void> restoreTask(String id);

  /// Permanently delete a trashed task.
  Future<void> permanentlyDeleteTask(String id);

  // --- Archive ---

  /// Archive a task (hide from main screens without deleting).
  Future<void> archiveTask(String id);

  /// Unarchive a task.
  Future<void> unarchiveTask(String id);
}
