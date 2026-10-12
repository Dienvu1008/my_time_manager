import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/services/task_completion_service.dart';

/// In-memory fake of [TaskRepository] that records the tasks passed to
/// updateTask, so we can assert the domain service's behaviour without SQLite.
class _FakeTaskRepository implements TaskRepository {
  final List<Task> updated = [];

  @override
  Future<void> updateTask(Task task) async => updated.add(task);

  // --- Unused by these tests ---
  @override
  Future<void> createTask(Task task) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<Task> getTask(String id) => throw UnimplementedError();
  @override
  Future<List<Task>> getTasks() async => const [];
  @override
  Future<List<Task>> getTasksOfTaskList(String taskListId) async => const [];
  @override
  Future<List<Task>> getTasksWithoutTaskList() async => const [];
  @override
  Future<void> moveTask(String taskId, String? newTaskListId) async {}
  @override
  Future<void> softDeleteTask(String id) async {}
  @override
  Future<void> restoreTask(String id) async {}
  @override
  Future<void> permanentlyDeleteTask(String id) async {}
  @override
  Future<void> archiveTask(String id) async {}
  @override
  Future<void> unarchiveTask(String id) async {}
}

void main() {
  late _FakeTaskRepository repo;
  late TaskCompletionService service;

  setUp(() {
    repo = _FakeTaskRepository();
    service = TaskCompletionService(repo);
  });

  group('toggleCompleted', () {
    test('flips an incomplete task to complete and persists it', () async {
      final task = Task(title: 'A', isCompleted: false);

      final result = await service.toggleCompleted(task);

      expect(result.isCompleted, isTrue);
      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.id, task.id);
      expect(repo.updated.single.isCompleted, isTrue);
    });

    test('flips a complete task back to incomplete', () async {
      final task = Task(title: 'A', isCompleted: true);

      final result = await service.toggleCompleted(task);

      expect(result.isCompleted, isFalse);
      expect(repo.updated.single.isCompleted, isFalse);
    });

    test('preserves the task identity and other fields', () async {
      final task = Task(title: 'Keep me', isImportant: true, isCompleted: false);

      final result = await service.toggleCompleted(task);

      expect(result.id, task.id);
      expect(result.title, 'Keep me');
      expect(result.isImportant, isTrue);
    });
  });

  group('setCompleted', () {
    test('sets completion explicitly and persists', () async {
      final task = Task(title: 'A', isCompleted: false);

      final result = await service.setCompleted(task, true);

      expect(result.isCompleted, isTrue);
      expect(repo.updated, hasLength(1));
    });
  });

  group('updateMeasurableProgress', () {
    test('updates howMuchHasBeenDone and persists', () async {
      final task = Task(
        title: 'Run',
        isMeasurable: true,
        howMuchHasBeenDone: 1.0,
      );

      final result = await service.updateMeasurableProgress(task, 5.5);

      expect(result.howMuchHasBeenDone, 5.5);
      expect(repo.updated.single.howMuchHasBeenDone, 5.5);
    });
  });
}
