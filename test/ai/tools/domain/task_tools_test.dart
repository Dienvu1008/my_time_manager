import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/tools/domain/task_tools.dart';
import 'package:my_time_manager/ai/tools/tool.dart';
import 'package:my_time_manager/ai/tools/tool_executor.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';
import 'package:my_time_manager/ai/tools/tool_result.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/services/task_completion_service.dart';

/// In-memory fake TaskRepository — no SQLite, no NotificationService coupling.
class _FakeTaskRepository implements TaskRepository {
  final Map<String, Task> _store = {};

  @override
  Future<void> createTask(Task task) async => _store[task.id] = task;
  @override
  Future<void> updateTask(Task task) async => _store[task.id] = task;
  @override
  Future<Task> getTask(String id) async {
    final t = _store[id];
    if (t == null) throw StateError('not found');
    return t;
  }

  @override
  Future<List<Task>> getTasks() async => _store.values.toList();
  @override
  Future<List<Task>> getTasksOfTaskList(String taskListId) async =>
      _store.values.where((t) => t.taskListId == taskListId).toList();
  @override
  Future<List<Task>> getTasksWithoutTaskList() async =>
      _store.values.where((t) => t.taskListId == null).toList();

  // Unused here.
  @override
  Future<void> deleteTask(String id) async {}
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
  late ToolExecutor exec;

  setUp(() {
    repo = _FakeTaskRepository();
    exec = ToolExecutor(ToolRegistry(
      taskTools(repo, TaskCompletionService(repo)),
    ));
  });

  test('create_task requires a title', () async {
    final r = await exec.execute('create_task', {});
    expect(r.success, isFalse);
    expect(r.errorCode, ToolResult.codeInvalidArguments);
  });

  test('create_task then get_task round-trips', () async {
    final created = await exec.execute('create_task', {
      'title': 'Write report',
      'isImportant': true,
    });
    expect(created.success, isTrue);
    final id = (created.data as Map)['id'] as String;

    final got = await exec.execute('get_task', {'id': id});
    expect(got.success, isTrue);
    expect((got.data as Map)['title'], 'Write report');
    expect((got.data as Map)['isImportant'], true);
  });

  test('get_task unknown id -> not_found', () async {
    final r = await exec.execute('get_task', {'id': 'nope'});
    expect(r.success, isFalse);
    expect(r.errorCode, ToolResult.codeNotFound);
  });

  test('list_tasks filters by list and by incomplete', () async {
    await repo.createTask(Task(title: 'A', taskListId: 'L1'));
    await repo.createTask(Task(title: 'B', taskListId: 'L2'));
    final done = Task(title: 'C', taskListId: 'L1', isCompleted: true);
    await repo.createTask(done);

    final byList = await exec.execute('list_tasks', {'taskListId': 'L1'});
    expect((byList.data as Map)['count'], 2);

    final incomplete = await exec
        .execute('list_tasks', {'taskListId': 'L1', 'onlyIncomplete': true});
    expect((incomplete.data as Map)['count'], 1);
  });

  test('update_task changes only provided fields', () async {
    final t = Task(title: 'Old', description: 'keep me');
    await repo.createTask(t);

    final r = await exec.execute('update_task', {'id': t.id, 'title': 'New'});
    expect(r.success, isTrue);
    final stored = await repo.getTask(t.id);
    expect(stored.title, 'New');
    expect(stored.description, 'keep me'); // untouched
  });

  test('update_task unknown id -> not_found', () async {
    final r = await exec.execute('update_task', {'id': 'nope', 'title': 'x'});
    expect(r.errorCode, ToolResult.codeNotFound);
  });

  test('complete_task marks complete (default) and can un-complete', () async {
    final t = Task(title: 'Do it');
    await repo.createTask(t);

    final done = await exec.execute('complete_task', {'id': t.id});
    expect((done.data as Map)['isCompleted'], true);
    expect((await repo.getTask(t.id)).isCompleted, isTrue);

    final undone =
        await exec.execute('complete_task', {'id': t.id, 'isCompleted': false});
    expect((undone.data as Map)['isCompleted'], false);
  });

  test('task tools expose the expected set incl. destructive delete_task', () {
    final tools = taskTools(repo, TaskCompletionService(repo));
    expect(tools.map((t) => t.name).toSet(), {
      'list_tasks',
      'get_task',
      'create_task',
      'update_task',
      'complete_task',
      'delete_task',
    });
    // delete_task is the only destructive one (always requires approval).
    final destructive =
        tools.where((t) => t.risk == ToolRisk.destructive).map((t) => t.name);
    expect(destructive, ['delete_task']);
  });
}
