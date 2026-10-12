@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/data/repositories/sqlite_archive_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_trash_repository.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/repositories/archive_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/trash_repository.dart';
import 'package:my_time_manager/domain/services/task_completion_service.dart';
import 'package:my_time_manager/screen_archive/model_archived_item.dart';
import 'package:my_time_manager/screen_trash/model_trashed_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// PHASE 7 — Agent-readiness proof.
///
/// This test demonstrates that a future AI agent can perform a complete,
/// realistic workflow against the real data store by depending ONLY on the
/// domain layer (repository interfaces + domain services) — never on
/// [DatabaseManager], raw SQL, or table names.
///
/// [_AgentToolbox] stands in for the tool layer an AI agent would call. It is
/// constructed exclusively from `domain/` abstractions. It has no field, import,
/// or reference of type [DatabaseManager] and issues no SQL. The dependency
/// direction it proves is:
///
///   AI Tool (this toolbox)
///        -> Domain Service / Repository (interfaces)
///        -> Data Repository (Sqlite* adapters, wired in main() only)
///        -> DatabaseManager
///        -> SQLite
///
/// The only place [DatabaseManager] appears in this file is the FFI in-memory
/// test harness (setUp), which mirrors how the production app owns the singleton
/// at startup. The toolbox itself is DatabaseManager-free by construction.
class _AgentToolbox {
  _AgentToolbox({
    required this.taskLists,
    required this.tasks,
    required this.trash,
    required this.archive,
    required this.taskCompletion,
  });

  final TaskListRepository taskLists;
  final TaskRepository tasks;
  final TrashRepository trash;
  final ArchiveRepository archive;
  final TaskCompletionService taskCompletion;

  // --- Tool-style operations an agent would expose ---

  Future<TaskList> createProject(String title) async {
    final list = TaskList(title: title);
    await taskLists.createTaskList(list);
    return list;
  }

  Future<Task> addTaskToProject(String title, String projectId) async {
    final task = Task(title: title, taskListId: projectId);
    await tasks.createTask(task);
    return task;
  }

  Future<Task> markDone(Task task) => taskCompletion.setCompleted(task, true);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _AgentToolbox agent;

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);

    // In production these Sqlite* adapters are provided app-wide via
    // MultiRepositoryProvider. Here we wire them the same way a composition root
    // would, then hand the agent ONLY the domain interfaces.
    final taskRepo = SqliteTaskRepository();
    agent = _AgentToolbox(
      taskLists: SqliteTaskListRepository(),
      tasks: taskRepo,
      trash: SqliteTrashRepository(),
      archive: SqliteArchiveRepository(),
      taskCompletion: TaskCompletionService(taskRepo),
    );
  });

  // NOTE ON SCOPE: TimeInterval create/update carries a *platform* side effect
  // (NotificationService schedules reminders, which instantiates an AudioPlayer
  // /flutter_local_notifications plugin). That path needs a Flutter binding +
  // plugin channel mocks and is therefore exercised in widget-level tests, not
  // this headless VM proof. The pure recurrence-expansion rule is proven against
  // a fake repository in recurrence_service_test.dart. This proof deliberately
  // covers the side-effect-free persistence lifecycle end to end.

  test(
      'agent completes a full workflow through the domain API only '
      '(create -> complete -> archive -> trash -> restore)',
      () async {
    // 1. Create a project and a task inside it.
    final project = await agent.createProject('Learn guitar');
    final task = await agent.addTaskToProject('Practice chords', project.id);

    expect((await agent.tasks.getTasks()).map((t) => t.id), contains(task.id));
    expect((await agent.tasks.getTasksOfTaskList(project.id)).map((t) => t.id),
        contains(task.id));

    // 2. Complete the task through the completion service.
    final done = await agent.markDone(task);
    expect(done.isCompleted, isTrue);
    expect((await agent.tasks.getTask(task.id)).isCompleted, isTrue,
        reason: 'completion must be persisted, not just returned');

    // 3. Archive the task; it disappears from the visible list and shows up in
    //    the aggregate archive view.
    await agent.tasks.archiveTask(task.id);
    expect((await agent.tasks.getTasks()).any((t) => t.id == task.id), isFalse);
    final archived = await agent.archive.getArchivedItems();
    expect(archived.map((i) => i.id), contains(task.id));
    expect(archived.firstWhere((i) => i.id == task.id).type,
        ArchivedItemType.task);

    // 4. Move the archived task to trash via the archive service, then confirm
    //    it lands in the trash aggregate.
    await agent.archive
        .moveToTrash(archived.firstWhere((i) => i.id == task.id));
    expect((await agent.archive.getArchivedItems()).any((i) => i.id == task.id),
        isFalse);
    final trashed = await agent.trash.getTrashedItems();
    expect(trashed.map((i) => i.id), contains(task.id));
    expect(trashed.firstWhere((i) => i.id == task.id).type,
        TrashedItemType.task);

    // 5. Restore from trash; the task becomes visible again with its completed
    //    state intact.
    await agent.trash.restore(trashed.firstWhere((i) => i.id == task.id));
    expect((await agent.trash.getTrashedItems()).any((i) => i.id == task.id),
        isFalse);
    final restored = await agent.tasks.getTask(task.id);
    expect(restored.isCompleted, isTrue,
        reason: 'restore must preserve the completed state');
    expect((await agent.tasks.getTasks()).map((t) => t.id), contains(task.id));
  });

  test('domain reads reflect writes made through a different repository instance',
      () async {
    // Proves the adapters share the same underlying store (the singleton) and
    // that an agent can freely construct fresh repository instances per tool
    // call without losing consistency.
    final project = await agent.createProject('Fitness');
    await SqliteTaskRepository()
        .createTask(Task(title: 'Run', taskListId: project.id));

    final viaAgent = await agent.tasks.getTasksOfTaskList(project.id);
    expect(viaAgent.map((t) => t.title), contains('Run'));
  });
}
