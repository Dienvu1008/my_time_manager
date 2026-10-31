import '../../../domain/models/model_project.dart';
import '../../../domain/models/model_project_item.dart';
import '../../../domain/repositories/project_repository.dart';
import '../../../domain/services/project_workspace_service.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';
import 'tool_views.dart';

/// Base for project tools (Core Track C8a). Data is reached only through
/// [ProjectRepository] / [ProjectWorkspaceService].
abstract class _ProjectTool extends Tool {
  const _ProjectTool(this.projects, this.workspace);
  final ProjectRepository projects;
  final ProjectWorkspaceService workspace;

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

  ToolResult projectNotFound(String id) =>
      ToolResult.failure(ToolResult.codeNotFound, 'No project with id "$id".');
}

/// `"value"` of a string argument for confirmation summaries, or `?`.
String _q(Map<String, dynamic> a, String key) {
  final v = a[key];
  return v is String && v.isNotEmpty ? '"$v"' : '?';
}

const _projectStatusSchema = {
  'type': 'string',
  'enum': ['active', 'onHold', 'completed', 'cancelled'],
};

/// Max entries per list in the workspace result (keeps prompts small).
const _maxWorkspaceList = 50;

class ListProjectsTool extends _ProjectTool {
  const ListProjectsTool(super.projects, super.workspace);
  @override
  String get name => 'list_projects';
  @override
  String get description =>
      'List visible projects (excludes trashed/archived). Optionally filter '
      'by status.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {'status': _projectStatusSchema},
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final status = args.optEnum('status', ProjectStatus.values);
        var items = await projects.getProjects();
        if (status != null) {
          items = items.where((p) => p.status == status).toList();
        }
        return ToolResult.ok({
          'count': items.length,
          'projects': items.map(ToolViews.project).toList(),
        });
      }, a);
}

class GetProjectWorkspaceTool extends _ProjectTool {
  const GetProjectWorkspaceTool(super.projects, super.workspace);
  @override
  String get name => 'get_project_workspace';
  @override
  String get description =>
      'Get a project workspace by id: its task lists, tasks (direct or via a '
      'linked list), notes, goals, calendar events and courses, with derived '
      'task completion. Descriptions are user data (marked untrusted).';
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
        final ws = await workspace.workspaceOf(id);
        if (ws == null) return projectNotFound(id);
        final description = ToolViews.untrusted(ws.project.description);
        final out = <String, dynamic>{
          ...ToolViews.project(ws.project),
          if (ws.project.isArchived) 'isArchived': true,
          if (ws.project.isDeleted) 'inTrash': true,
          if (description != null) 'description': description,
        };
        void put<T>(String key, List<T> items,
            Map<String, dynamic> Function(T) view) {
          out[key] = items.take(_maxWorkspaceList).map(view).toList();
          if (items.length > _maxWorkspaceList) {
            out['${key}Total'] = items.length;
          }
        }

        put('taskLists', ws.taskLists,
            (l) => {'id': l.id, 'title': l.title});
        put(
            'tasks',
            ws.tasks,
            (t) => {
                  'id': t.task.id,
                  'title': t.task.title,
                  'isCompleted': t.task.isCompleted,
                  'isDirect': t.isDirect,
                  if (t.viaTaskListId != null) 'viaTaskListId': t.viaTaskListId,
                });
        put('notes', ws.notes, (n) => {'id': n.id, 'title': n.title});
        put(
            'goals',
            ws.goals,
            (g) => {
                  'id': g.goal.id,
                  'title': g.goal.title,
                  if (g.progress != null)
                    'progressPercent': ToolViews.percent(g.progress!.ratio),
                });
        put(
            'calendarEvents',
            ws.calendarEvents,
            (e) => {
                  'id': e.id,
                  'title': e.title,
                  'start': e.start.effective.toIso8601String(),
                });
        put(
            'courses',
            ws.courses,
            (c) => {
                  'id': c.course.id,
                  'title': c.course.title,
                  if (c.progress != null)
                    'progressPercent': ToolViews.percent(c.progress!.ratio),
                });
        out['totalTasks'] = ws.totalTasks;
        out['completedTasks'] = ws.completedTasks;
        out['taskCompletionPercent'] =
            ToolViews.percent(ws.taskCompletionRatio);
        out['ignoredItemCount'] = ws.ignoredItemCount;
        return ToolResult.ok(out);
      }, a);
}

class CreateProjectTool extends _ProjectTool implements ConfirmationDescriber {
  const CreateProjectTool(super.projects, super.workspace);
  @override
  String get name => 'create_project';
  @override
  String get description =>
      'Create a new project. Only a title is required; description, '
      'startDate, targetDate (ISO-8601) and status are optional.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'startDate': {'type': 'string', 'description': 'ISO-8601 date.'},
          'targetDate': {'type': 'string', 'description': 'ISO-8601 date.'},
          'status': _projectStatusSchema,
        },
        'required': ['title'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Create project ${_q(a, 'title')}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final project = Project(
          title: args.requireString('title'),
          description: args.optString('description'),
          startDate: args.optDateTime('startDate'),
          targetDate: args.optDateTime('targetDate'),
          status: args.optEnum('status', ProjectStatus.values),
        );
        await projects.createProject(project);
        return ToolResult.ok(ToolViews.project(project));
      }, a);
}

class AddProjectItemTool extends _ProjectTool implements ConfirmationDescriber {
  const AddProjectItemTool(super.projects, super.workspace);
  @override
  String get name => 'add_project_item';
  @override
  String get description =>
      'Add an existing entity (taskList, task, note, goal, calendarEvent or '
      'course) to a project. Adding it again is a no-op.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'projectId': {'type': 'string'},
          'entityType': {'type': 'string', 'enum': ProjectEntityType.supported},
          'entityId': {'type': 'string'},
        },
        'required': ['projectId', 'entityType', 'entityId'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Add ${a['entityType'] is String ? a['entityType'] : 'item'} '
      '${_q(a, 'entityId')} to project ${_q(a, 'projectId')}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final projectId = args.requireString('projectId');
        final entityType = args.requireString('entityType');
        final entityId = args.requireString('entityId');
        if (!ProjectEntityType.supported.contains(entityType)) {
          throw ToolArgumentError('"entityType" must be one of: '
              '${ProjectEntityType.supported.join(', ')}.');
        }
        if (await projects.getProject(projectId) == null) {
          return projectNotFound(projectId);
        }
        final item = await projects.addItem(projectId, entityType, entityId);
        return ToolResult.ok({
          'itemId': item.id,
          'projectId': item.projectId,
          'entityType': item.entityType,
          'entityId': item.entityId,
        });
      }, a);
}

class ArchiveProjectTool extends _ProjectTool implements ConfirmationDescriber {
  const ArchiveProjectTool(super.projects, super.workspace);
  @override
  String get name => 'archive_project';
  @override
  String get description =>
      'Archive a project by id (hidden from lists; can be unarchived). Always '
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
      'Archive project ${_q(a, 'id')} (can be unarchived later).';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        if (await projects.getProject(id) == null) return projectNotFound(id);
        await projects.archiveProject(id);
        return ToolResult.ok({'id': id, 'archived': true});
      }, a);
}

class TrashProjectTool extends _ProjectTool implements ConfirmationDescriber {
  const TrashProjectTool(super.projects, super.workspace);
  @override
  String get name => 'trash_project';
  @override
  String get description =>
      'Move a project to the trash by id (soft delete — the user can restore '
      'it from the Trash; linked items are untouched). Always requires '
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
  String confirmationSummary(Map<String, dynamic> a) =>
      'Move project ${_q(a, 'id')} to trash (can be restored from Trash).';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        if (await projects.getProject(id) == null) return projectNotFound(id);
        await projects.softDeleteProject(id);
        return ToolResult.ok({'id': id, 'trashed': true});
      }, a);
}

/// Convenience: build all project tools.
List<Tool> projectTools(
        ProjectRepository projects, ProjectWorkspaceService workspace) =>
    [
      ListProjectsTool(projects, workspace),
      GetProjectWorkspaceTool(projects, workspace),
      CreateProjectTool(projects, workspace),
      AddProjectItemTool(projects, workspace),
      ArchiveProjectTool(projects, workspace),
      TrashProjectTool(projects, workspace),
    ];
