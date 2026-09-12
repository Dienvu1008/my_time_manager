import '../../../data/models/model_task.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/services/task_completion_service.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';
import 'tool_views.dart';

/// Base for task tools: shares the repository/service and the invalid-args
/// guard so each tool's [execute] stays focused on its own logic.
abstract class _TaskTool extends Tool {
  const _TaskTool(this.tasks, this.completion);
  final TaskRepository tasks;
  final TaskCompletionService completion;

  Future<ToolResult> guarded(
      Future<ToolResult> Function(ToolArgs args) body, Map<String, dynamic> a) async {
    try {
      return await body(ToolArgs(a));
    } on ToolArgumentError catch (e) {
      return ToolResult.failure(ToolResult.codeInvalidArguments, e.message);
    }
  }
}

class ListTasksTool extends _TaskTool {
  const ListTasksTool(super.tasks, super.completion);
  @override
  String get name => 'list_tasks';
  @override
  String get description =>
      'List visible tasks (excludes trashed/archived). Optionally filter by '
      'taskListId, or only incomplete tasks.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'taskListId': {
            'type': 'string',
            'description': 'Only tasks in this list.'
          },
          'onlyIncomplete': {'type': 'boolean'},
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final listId = args.optString('taskListId');
        final onlyIncomplete = args.optBool('onlyIncomplete');
        var items = listId != null
            ? await tasks.getTasksOfTaskList(listId)
            : await tasks.getTasks();
        if (onlyIncomplete) {
          items = items.where((t) => !t.isCompleted).toList();
        }
        return ToolResult.ok({
          'count': items.length,
          'tasks': items.map(ToolViews.task).toList(),
        });
      }, a);
}

class GetTaskTool extends _TaskTool {
  const GetTaskTool(super.tasks, super.completion);
  @override
  String get name => 'get_task';
  @override
  String get description => 'Get a single task by id.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'}
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        try {
          final task = await tasks.getTask(id);
          return ToolResult.ok(ToolViews.task(task));
        } catch (_) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No task with id "$id".');
        }
      }, a);
}

class CreateTaskTool extends _TaskTool {
  const CreateTaskTool(super.tasks, super.completion);
  @override
  String get name => 'create_task';
  @override
  String get description =>
      'Create a new task. Only a title is required; taskListId, importance and '
      'a description are optional.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'taskListId': {'type': 'string'},
          'isImportant': {'type': 'boolean'},
          'description': {'type': 'string'},
        },
        'required': ['title'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final task = Task(
          title: args.requireString('title'),
          taskListId: args.optString('taskListId'),
          isImportant: args.optBool('isImportant'),
          description: args.optString('description'),
        );
        await tasks.createTask(task);
        return ToolResult.ok(ToolViews.task(task));
      }, a);
}

class UpdateTaskTool extends _TaskTool {
  const UpdateTaskTool(super.tasks, super.completion);
  @override
  String get name => 'update_task';
  @override
  String get description =>
      'Update an existing task by id. Provide only the fields to change '
      '(title, isImportant, description).';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'title': {'type': 'string'},
          'isImportant': {'type': 'boolean'},
          'description': {'type': 'string'},
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final Task existing;
        try {
          existing = await tasks.getTask(id);
        } catch (_) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No task with id "$id".');
        }
        final updated = existing.copyWith(
          title: args.optString('title'),
          isImportant: args.has('isImportant') ? args.optBool('isImportant') : null,
          description: args.optString('description'),
        );
        await tasks.updateTask(updated);
        return ToolResult.ok(ToolViews.task(updated));
      }, a);
}

class CompleteTaskTool extends _TaskTool {
  const CompleteTaskTool(super.tasks, super.completion);
  @override
  String get name => 'complete_task';
  @override
  String get description =>
      'Mark a task complete or incomplete by id. Uses the completion service so '
      'the same business rule as the UI is applied.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'isCompleted': {'type': 'boolean', 'description': 'Defaults to true.'},
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final isCompleted = args.optBool('isCompleted', fallback: true);
        final Task existing;
        try {
          existing = await tasks.getTask(id);
        } catch (_) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No task with id "$id".');
        }
        final updated = await completion.setCompleted(existing, isCompleted);
        return ToolResult.ok(ToolViews.task(updated));
      }, a);
}

class DeleteTaskTool extends _TaskTool {
  const DeleteTaskTool(super.tasks, super.completion);
  @override
  String get name => 'delete_task';
  @override
  String get description =>
      'Move a task to the trash by id (soft delete — the user can restore it '
      'from the Trash). This is a destructive action and always requires '
      'explicit user approval.';
  @override
  ToolRisk get risk => ToolRisk.destructive;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'}
        },
        'required': ['id'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        try {
          await tasks.getTask(id);
        } catch (_) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No task with id "$id".');
        }
        await tasks.softDeleteTask(id);
        return ToolResult.ok({'id': id, 'deleted': true});
      }, a);
}

/// Convenience: build all task tools from the shared dependencies.
List<Tool> taskTools(TaskRepository tasks, TaskCompletionService completion) => [
      ListTasksTool(tasks, completion),
      GetTaskTool(tasks, completion),
      CreateTaskTool(tasks, completion),
      UpdateTaskTool(tasks, completion),
      CompleteTaskTool(tasks, completion),
      DeleteTaskTool(tasks, completion),
    ];
