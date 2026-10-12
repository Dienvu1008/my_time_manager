import '../models/model_list.dart';

/// Domain boundary for **task lists**.
///
/// Callers (UI, blocs, controllers, and — in the future — AI tools) depend on
/// this interface, never on [DatabaseManager] / SQLite directly. Implementations
/// live in `lib/data/repositories/` and adapt to the existing persistence layer.
///
/// Trash (soft-delete) and archive are modelled here as *capabilities of the
/// task-list domain* rather than as separate repositories, because they operate
/// on task lists (and cascade to their child tasks) — they are not a standalone
/// boundary of their own.
abstract class TaskListRepository {
  /// All visible task lists (excludes trashed and archived).
  Future<List<TaskList>> getTaskLists();

  /// A single task list by id.
  Future<TaskList> getTaskList(String id);

  /// Create a new task list.
  Future<void> createTaskList(TaskList taskList);

  /// Update an existing task list.
  Future<void> updateTaskList(TaskList taskList);

  /// Hard-delete a task list (cascades to child tasks via FK). Prefer
  /// [softDeleteTaskList] for user-facing deletes.
  Future<void> deleteTaskList(String id);

  // --- Trash (soft-delete) ---

  /// Move a task list to trash, cascading to its (not-yet-deleted) child tasks.
  Future<void> softDeleteTaskList(String id);

  /// Restore a task list from trash (restores children deleted together with it).
  Future<void> restoreTaskList(String id);

  /// Permanently delete a trashed task list.
  Future<void> permanentlyDeleteTaskList(String id);

  // --- Archive ---

  /// Archive a task list, cascading to its child tasks.
  Future<void> archiveTaskList(String id);

  /// Unarchive a task list (unarchives children archived together with it).
  Future<void> unarchiveTaskList(String id);
}
