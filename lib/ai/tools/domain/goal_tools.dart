import '../../../domain/models/model_goal.dart';
import '../../../domain/models/model_milestone.dart';
import '../../../domain/repositories/goal_repository.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/services/goal_progress_service.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';
import 'tool_views.dart';

/// Base for goal / milestone tools (Core Track C8a): shares the domain
/// dependencies and the invalid-args guard. Data is reached only through
/// [GoalRepository] / [GoalProgressService] / [TaskRepository].
abstract class _GoalTool extends Tool {
  const _GoalTool(this.goals, this.progress, this.tasks);
  final GoalRepository goals;
  final GoalProgressService progress;
  final TaskRepository tasks;

  Future<ToolResult> guarded(
      Future<ToolResult> Function(ToolArgs args) body, Map<String, dynamic> a) async {
    try {
      return await body(ToolArgs(a));
    } on ToolArgumentError catch (e) {
      return ToolResult.failure(ToolResult.codeInvalidArguments, e.message);
    } on ArgumentError catch (e) {
      return ToolResult.failure(
          ToolResult.codeInvalidArguments, '${e.message}');
    }
  }

  ToolResult goalNotFound(String id) =>
      ToolResult.failure(ToolResult.codeNotFound, 'No goal with id "$id".');

  ToolResult milestoneNotFound(String id) => ToolResult.failure(
      ToolResult.codeNotFound, 'No milestone with id "$id".');
}

/// `"value"` of a string argument for confirmation summaries, or `?`.
String _q(Map<String, dynamic> a, String key) {
  final v = a[key];
  return v is String && v.isNotEmpty ? '"$v"' : '?';
}

const _goalStatusSchema = {
  'type': 'string',
  'enum': ['active', 'paused', 'completed', 'abandoned'],
};

class ListGoalsTool extends _GoalTool {
  const ListGoalsTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'list_goals';
  @override
  String get description =>
      'List visible goals (excludes trashed/archived) with their derived '
      'progress percent. Optionally filter by status.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {'status': _goalStatusSchema},
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final status = args.optEnum('status', GoalStatus.values);
        var items = await goals.getGoals();
        if (status != null) {
          items = items.where((g) => g.status == status).toList();
        }
        return ToolResult.ok({
          'count': items.length,
          'goals': [
            for (final g in items)
              ToolViews.goal(g, progress: await progress.progressOf(g.id)),
          ],
        });
      }, a);
}

class GetGoalTool extends _GoalTool {
  const GetGoalTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'get_goal';
  @override
  String get description =>
      'Get a goal by id with its milestones, linked items and derived '
      'progress. Descriptions are user data (marked untrusted).';
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
        final goal = await goals.getGoal(id);
        if (goal == null) return goalNotFound(id);
        final milestones = await goals.getMilestones(id);
        final links = await goals.getLinks(id);
        final p = await progress.progressOf(id);
        final perMilestone = {
          for (final mp in p?.milestones ?? const <MilestoneProgress>[])
            mp.milestoneId: mp,
        };
        final description = ToolViews.untrusted(goal.description);
        return ToolResult.ok({
          ...ToolViews.goal(goal),
          if (goal.isArchived) 'isArchived': true,
          if (goal.isDeleted) 'inTrash': true,
          if (description != null) 'description': description,
          if (p != null)
            'progress': {
              'percent': ToolViews.percent(p.ratio),
              'doneMilestones': p.doneMilestones,
              'totalMilestones': p.totalMilestones,
              'directCompletedTasks': p.directCompletedTasks,
              'directTotalTasks': p.directTotalTasks,
            },
          'milestones': [
            for (final m in milestones)
              ToolViews.milestone(m, progress: perMilestone[m.id]),
          ],
          'links': [
            for (final l in links)
              {
                'entityType': l.entityType,
                'entityId': l.entityId,
                if (l.milestoneId != null) 'milestoneId': l.milestoneId,
              },
          ],
        });
      }, a);
}

class CreateGoalTool extends _GoalTool implements ConfirmationDescriber {
  const CreateGoalTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'create_goal';
  @override
  String get description =>
      'Create a new goal. Only a title is required; description, targetDate '
      '(ISO-8601) and status are optional.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'targetDate': {'type': 'string', 'description': 'ISO-8601 date.'},
          'status': _goalStatusSchema,
        },
        'required': ['title'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Create goal ${_q(a, 'title')}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final goal = Goal(
          title: args.requireString('title'),
          description: args.optString('description'),
          targetDate: args.optDateTime('targetDate'),
          status: args.optEnum('status', GoalStatus.values),
        );
        await goals.createGoal(goal);
        return ToolResult.ok(ToolViews.goal(goal));
      }, a);
}

class UpdateGoalTool extends _GoalTool implements ConfirmationDescriber {
  const UpdateGoalTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'update_goal';
  @override
  String get description =>
      'Update a goal by id. Provide only the fields to change (title, '
      'description, targetDate, clearTargetDate, status).';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'targetDate': {'type': 'string', 'description': 'ISO-8601 date.'},
          'clearTargetDate': {'type': 'boolean'},
          'status': _goalStatusSchema,
        },
        'required': ['id'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Update goal ${_q(a, 'id')}'
      '${a['title'] is String ? ' (new title ${_q(a, 'title')})' : ''}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final title = args.optString('title');
        if (title != null && title.trim().isEmpty) {
          throw const ToolArgumentError('"title" must not be empty.');
        }
        final description = args.optString('description');
        final targetDate = args.optDateTime('targetDate');
        final clearTargetDate = args.optBool('clearTargetDate');
        final status = args.optEnum('status', GoalStatus.values);
        final existing = await goals.getGoal(id);
        if (existing == null) return goalNotFound(id);
        final updated = existing.copyWith(
          title: title,
          description: description,
          targetDate: targetDate,
          clearTargetDate: clearTargetDate,
          status: status,
          updateTimeStamp: DateTime.now(),
        );
        await goals.updateGoal(updated);
        return ToolResult.ok(ToolViews.goal(updated));
      }, a);
}

class CreateMilestoneTool extends _GoalTool implements ConfirmationDescriber {
  const CreateMilestoneTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'create_milestone';
  @override
  String get description =>
      'Add a milestone to a goal (appended after the existing milestones). '
      'description and dueDate (ISO-8601) are optional.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'goalId': {'type': 'string'},
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'dueDate': {'type': 'string', 'description': 'ISO-8601 date.'},
        },
        'required': ['goalId', 'title'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Add milestone ${_q(a, 'title')} to goal ${_q(a, 'goalId')}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final goalId = args.requireString('goalId');
        final title = args.requireString('title');
        final description = args.optString('description');
        final dueDate = args.optDateTime('dueDate');
        if (await goals.getGoal(goalId) == null) return goalNotFound(goalId);
        final existing = await goals.getMilestones(goalId);
        final milestone = Milestone(
          goalId: goalId,
          title: title,
          description: description,
          dueDate: dueDate,
          sortOrder: existing.length,
        );
        await goals.createMilestone(milestone);
        return ToolResult.ok(ToolViews.milestone(milestone));
      }, a);
}

class UpdateMilestoneTool extends _GoalTool implements ConfirmationDescriber {
  const UpdateMilestoneTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'update_milestone';
  @override
  String get description =>
      'Update a milestone by id. Provide only the fields to change (title, '
      'description, dueDate, clearDueDate, isCompleted).';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'dueDate': {'type': 'string', 'description': 'ISO-8601 date.'},
          'clearDueDate': {'type': 'boolean'},
          'isCompleted': {'type': 'boolean'},
        },
        'required': ['id'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) {
    final done = a['isCompleted'];
    final mark = done == true
        ? ' and mark it completed'
        : done == false
            ? ' and mark it not completed'
            : '';
    return 'Update milestone ${_q(a, 'id')}$mark.';
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final title = args.optString('title');
        if (title != null && title.trim().isEmpty) {
          throw const ToolArgumentError('"title" must not be empty.');
        }
        final description = args.optString('description');
        final dueDate = args.optDateTime('dueDate');
        final clearDueDate = args.optBool('clearDueDate');
        final isCompleted =
            args.has('isCompleted') ? args.optBool('isCompleted') : null;
        final existing = await goals.getMilestone(id);
        if (existing == null) return milestoneNotFound(id);
        if (title != null ||
            description != null ||
            dueDate != null ||
            clearDueDate) {
          await goals.updateMilestone(existing.copyWith(
            title: title,
            description: description,
            dueDate: dueDate,
            clearDueDate: clearDueDate,
            updateTimeStamp: DateTime.now(),
          ));
        }
        if (isCompleted != null && isCompleted != existing.isCompleted) {
          // Through the repository so completedAt is stamped/cleared.
          await goals.setMilestoneCompleted(id, isCompleted);
        }
        final updated = await goals.getMilestone(id) ?? existing;
        return ToolResult.ok(ToolViews.milestone(updated));
      }, a);
}

class LinkTaskToGoalTool extends _GoalTool implements ConfirmationDescriber {
  const LinkTaskToGoalTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'link_task_to_goal';
  @override
  String get description =>
      'Link a task to a goal, optionally under one of that goal\'s '
      'milestones. Linking again moves the task to the given milestone.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'goalId': {'type': 'string'},
          'taskId': {'type': 'string'},
          'milestoneId': {'type': 'string'},
        },
        'required': ['goalId', 'taskId'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Link task ${_q(a, 'taskId')} to goal ${_q(a, 'goalId')}'
      '${a['milestoneId'] is String ? ' under milestone ${_q(a, 'milestoneId')}' : ''}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final goalId = args.requireString('goalId');
        final taskId = args.requireString('taskId');
        final milestoneId = args.optString('milestoneId');
        if (await goals.getGoal(goalId) == null) return goalNotFound(goalId);
        try {
          await tasks.getTask(taskId);
        } catch (_) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No task with id "$taskId".');
        }
        if (milestoneId != null) {
          final m = await goals.getMilestone(milestoneId);
          if (m == null) return milestoneNotFound(milestoneId);
          if (m.goalId != goalId) {
            return ToolResult.failure(ToolResult.codeInvalidArguments,
                'Milestone "$milestoneId" does not belong to goal "$goalId".');
          }
        }
        final link =
            await goals.linkTask(goalId, taskId, milestoneId: milestoneId);
        return ToolResult.ok({
          'linkId': link.id,
          'goalId': link.goalId,
          'taskId': link.entityId,
          if (link.milestoneId != null) 'milestoneId': link.milestoneId,
        });
      }, a);
}

class ArchiveGoalTool extends _GoalTool implements ConfirmationDescriber {
  const ArchiveGoalTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'archive_goal';
  @override
  String get description =>
      'Archive a goal by id (hidden from lists; can be unarchived). Always '
      'requires explicit user approval.';
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
  String confirmationSummary(Map<String, dynamic> a) =>
      'Archive goal ${_q(a, 'id')} (can be unarchived later).';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        if (await goals.getGoal(id) == null) return goalNotFound(id);
        await goals.archiveGoal(id);
        return ToolResult.ok({'id': id, 'archived': true});
      }, a);
}

class TrashGoalTool extends _GoalTool implements ConfirmationDescriber {
  const TrashGoalTool(super.goals, super.progress, super.tasks);
  @override
  String get name => 'trash_goal';
  @override
  String get description =>
      'Move a goal to the trash by id (soft delete — the user can restore it '
      'from the Trash). Always requires explicit user approval.';
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
  String confirmationSummary(Map<String, dynamic> a) =>
      'Move goal ${_q(a, 'id')} to trash (can be restored from Trash).';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        if (await goals.getGoal(id) == null) return goalNotFound(id);
        await goals.softDeleteGoal(id);
        return ToolResult.ok({'id': id, 'trashed': true});
      }, a);
}

/// Convenience: build all goal / milestone tools.
List<Tool> goalTools(
        GoalRepository goals, GoalProgressService progress, TaskRepository tasks) =>
    [
      ListGoalsTool(goals, progress, tasks),
      GetGoalTool(goals, progress, tasks),
      CreateGoalTool(goals, progress, tasks),
      UpdateGoalTool(goals, progress, tasks),
      CreateMilestoneTool(goals, progress, tasks),
      UpdateMilestoneTool(goals, progress, tasks),
      LinkTaskToGoalTool(goals, progress, tasks),
      ArchiveGoalTool(goals, progress, tasks),
      TrashGoalTool(goals, progress, tasks),
    ];
