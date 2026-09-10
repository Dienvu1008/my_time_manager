import '../../data/models/model_task.dart';
import '../repositories/task_repository.dart';

/// Domain rules for changing a task's completion / measurable progress.
///
/// These rules were previously duplicated inline across several widgets
/// (task overview, timeline screens, the calendar data controller). Centralising
/// them here gives a single source of truth that both the UI and a future AI
/// tool can call:
///
///     UI / AI Tool → TaskCompletionService → TaskRepository → DatabaseManager
///
/// Each method returns the updated [Task] so callers that keep an in-memory copy
/// (optimistic UI) can refresh their local state — behaviour is identical to the
/// previous inline `copyWith(...)` + `updateTask(...)` sequence.
class TaskCompletionService {
  TaskCompletionService(this._tasks);

  final TaskRepository _tasks;

  /// Toggle a task between completed and not-completed. Returns the new state.
  Future<Task> toggleCompleted(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _tasks.updateTask(updated);
    return updated;
  }

  /// Set completion explicitly. Returns the new state (persists even if the
  /// value is unchanged, matching the previous inline behaviour).
  Future<Task> setCompleted(Task task, bool isCompleted) async {
    final updated = task.copyWith(isCompleted: isCompleted);
    await _tasks.updateTask(updated);
    return updated;
  }

  /// Update a measurable task's "how much has been done" progress. Returns the
  /// new state. Callers are responsible for parsing user input into [amount];
  /// this mirrors the previous inline `double.parse(...)` at the call sites.
  Future<Task> updateMeasurableProgress(Task task, double amount) async {
    final updated = task.copyWith(howMuchHasBeenDone: amount);
    await _tasks.updateTask(updated);
    return updated;
  }
}
