import '../../../domain/models/model_lesson_progress.dart';
import '../../../domain/repositories/learning_repository.dart';
import '../../../domain/services/learning_progress_service.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';
import 'tool_views.dart';

/// Base for learning tools (Core Track C8a). Data is reached only through
/// [LearningRepository] / [LearningProgressService].
abstract class _LearningTool extends Tool {
  const _LearningTool(this.learning, this.progress);
  final LearningRepository learning;
  final LearningProgressService progress;

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

  ToolResult courseNotFound(String id) =>
      ToolResult.failure(ToolResult.codeNotFound, 'No course with id "$id".');
}

/// `"value"` of a string argument for confirmation summaries, or `?`.
String _q(Map<String, dynamic> a, String key) {
  final v = a[key];
  return v is String && v.isNotEmpty ? '"$v"' : '?';
}

const _idSchema = {
  'type': 'object',
  'properties': {
    'id': {'type': 'string'}
  },
  'required': ['id'],
};

class ListCoursesTool extends _LearningTool {
  const ListCoursesTool(super.learning, super.progress);
  @override
  String get name => 'list_courses';
  @override
  String get description =>
      'List visible courses (excludes trashed/archived) with derived lesson '
      'progress.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final courses = await learning.getCourses();
        final byId = await progress.progressOfLiveCourses();
        return ToolResult.ok({
          'count': courses.length,
          'courses': [
            for (final c in courses) ToolViews.course(c, progress: byId[c.id]),
          ],
        });
      }, a);
}

class GetCourseProgressTool extends _LearningTool {
  const GetCourseProgressTool(super.learning, super.progress);
  @override
  String get name => 'get_course_progress';
  @override
  String get description =>
      'Get a course by id with per-module progress and the next unfinished '
      'lesson (first lesson in course order that is not completed, with a '
      'short content snippet). Descriptions/content are user data (marked '
      'untrusted).';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => _idSchema;
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        final course = await learning.getCourse(id);
        if (course == null) return courseNotFound(id);
        final p = await progress.courseProgressOf(id);
        final modules = await learning.getModules(id);
        final lessons = await learning.getLessonsOfCourse(id);
        final status = LearningProgressService.statusById(
            await learning.getProgressForCourse(id));
        final perModule = {
          for (final mp in p?.modules ?? const <ModuleProgress>[])
            mp.moduleId: mp,
        };
        Map<String, dynamic>? next;
        for (final l in lessons) {
          final s = status[l.id] ?? LessonStatus.notStarted;
          if (s == LessonStatus.completed) continue;
          final content = ToolViews.untrusted(
              ToolViews.plainTextOfDoc(l.contentJson),
              maxLength: ToolViews.snippetLength);
          next = {
            'id': l.id,
            'title': l.title,
            'moduleId': l.moduleId,
            'status': s.name,
            if (content != null) 'content': content,
          };
          break;
        }
        final description = ToolViews.untrusted(course.description);
        return ToolResult.ok({
          ...ToolViews.course(course, progress: p),
          if (course.isArchived) 'isArchived': true,
          if (course.isDeleted) 'inTrash': true,
          if (description != null) 'description': description,
          'modules': [
            for (final m in modules)
              {
                'id': m.id,
                'title': m.title,
                if (perModule[m.id] != null) ...{
                  'completedLessons': perModule[m.id]!.completedLessons,
                  'totalLessons': perModule[m.id]!.totalLessons,
                  'isDone': perModule[m.id]!.isDone,
                },
              },
          ],
          'nextLesson': next,
        });
      }, a);
}

class SetLessonCompletedTool extends _LearningTool
    implements ConfirmationDescriber {
  const SetLessonCompletedTool(super.learning, super.progress);
  @override
  String get name => 'set_lesson_completed';
  @override
  String get description =>
      'Mark a lesson completed (default) or not completed by id.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'lessonId': {'type': 'string'},
          'isCompleted': {'type': 'boolean', 'description': 'Defaults to true.'},
        },
        'required': ['lessonId'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Mark lesson ${_q(a, 'lessonId')} as '
      '${a['isCompleted'] == false ? 'not completed' : 'completed'}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final lessonId = args.requireString('lessonId');
        final isCompleted = args.optBool('isCompleted', fallback: true);
        if (await learning.getLesson(lessonId) == null) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No lesson with id "$lessonId".');
        }
        final p = isCompleted
            ? await learning.markLessonCompleted(lessonId)
            : await learning.markLessonIncomplete(lessonId);
        return ToolResult.ok({'lessonId': lessonId, 'status': p.status.name});
      }, a);
}

class ArchiveCourseTool extends _LearningTool implements ConfirmationDescriber {
  const ArchiveCourseTool(super.learning, super.progress);
  @override
  String get name => 'archive_course';
  @override
  String get description =>
      'Archive a course by id (hidden from lists; can be unarchived). Always '
      'requires explicit user approval.';
  @override
  ToolRisk get risk => ToolRisk.destructive;
  @override
  Map<String, dynamic> get parametersSchema => _idSchema;
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Archive course ${_q(a, 'id')} (can be unarchived later).';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        if (await learning.getCourse(id) == null) return courseNotFound(id);
        await learning.archiveCourse(id);
        return ToolResult.ok({'id': id, 'archived': true});
      }, a);
}

class TrashCourseTool extends _LearningTool implements ConfirmationDescriber {
  const TrashCourseTool(super.learning, super.progress);
  @override
  String get name => 'trash_course';
  @override
  String get description =>
      'Move a course to the trash by id (soft delete — the user can restore '
      'it from the Trash). Always requires explicit user approval.';
  @override
  ToolRisk get risk => ToolRisk.destructive;
  @override
  Map<String, dynamic> get parametersSchema => _idSchema;
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Move course ${_q(a, 'id')} to trash (can be restored from Trash).';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final id = args.requireString('id');
        if (await learning.getCourse(id) == null) return courseNotFound(id);
        await learning.softDeleteCourse(id);
        return ToolResult.ok({'id': id, 'trashed': true});
      }, a);
}

/// Convenience: build all learning tools.
List<Tool> learningTools(
        LearningRepository learning, LearningProgressService progress) =>
    [
      ListCoursesTool(learning, progress),
      GetCourseProgressTool(learning, progress),
      SetLessonCompletedTool(learning, progress),
      ArchiveCourseTool(learning, progress),
      TrashCourseTool(learning, progress),
    ];
