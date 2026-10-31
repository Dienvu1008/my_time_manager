import 'dart:convert';
import 'dart:math' as math;

import '../../../domain/models/model_calendar_event.dart';
import '../../../domain/models/model_course.dart';
import '../../../domain/models/model_goal.dart';
import '../../../domain/models/model_milestone.dart';
import '../../../domain/models/model_project.dart';
import '../../../domain/models/model_task.dart';
import '../../../domain/models/model_time_interval.dart';
import '../../../domain/services/goal_progress_service.dart';
import '../../../domain/services/learning_progress_service.dart';

/// Compact, deterministic JSON views of domain models for tool results. These
/// are intentionally smaller than the full model maps: they expose only the
/// fields an agent needs to reason about, avoiding noisy/large prompts.
///
/// Untrusted-data convention (Core Track C8a): free text written by the user
/// or imported from elsewhere (goal / milestone / project / course
/// descriptions, note snippets, lesson content) is returned wrapped by
/// [untrusted] as `{'untrusted': true, 'text': ..., 'truncated'?: true}` so the
/// model can tell DATA from instructions. Titles stay plain strings (same as
/// the task views). Full prompt-injection hardening is Phase C8b.
class ToolViews {
  const ToolViews._();

  /// Max length of a text snippet in tool results (note search, lesson
  /// content).
  static const int snippetLength = 300;

  static Map<String, dynamic> task(Task t) => {
        'id': t.id,
        'title': t.title,
        'isCompleted': t.isCompleted,
        'isImportant': t.isImportant,
        if (t.taskListId != null) 'taskListId': t.taskListId,
        if (t.description.isNotEmpty) 'description': t.description,
        'isMeasurable': t.isMeasurable,
        if (t.isMeasurable) 'howMuchHasBeenDone': t.howMuchHasBeenDone,
        if (t.isMeasurable) 'unit': t.unit,
        if (t.subtasks.isNotEmpty)
          'subtasks': [
            for (final s in t.subtasks)
              {'id': s.id, 'title': s.title, 'isCompleted': s.isCompleted}
          ],
      };

  static Map<String, dynamic> timeInterval(TimeInterval ti) => {
        'id': ti.id,
        'title': ti.title,
        'isCompleted': ti.isCompleted,
        if (ti.taskId != null) 'taskId': ti.taskId,
        if (ti.subtaskId != null) 'subtaskId': ti.subtaskId,
        'startDate': ti.startDate?.toIso8601String(),
        'endDate': ti.endDate?.toIso8601String(),
        'startTime': _time(ti.startTime),
        'endTime': _time(ti.endTime),
        'isStartTimeUndefined': ti.isStartTimeUndefined,
      };

  static Map<String, dynamic> calendarEvent(CalendarEvent e) => {
        'id': e.id,
        'title': e.title,
        if (e.taskListId != null) 'taskListId': e.taskListId,
        if (e.location.isNotEmpty) 'location': e.location,
        'isAllDay': e.start.isAllDay,
        'start': e.start.effective.toIso8601String(),
        'end': e.end.effective.toIso8601String(),
        'status': e.status.apiValue,
      };

  /// Compact goal view; adds `progressPercent` when [progress] is given.
  static Map<String, dynamic> goal(Goal g, {GoalProgress? progress}) => {
        'id': g.id,
        'title': g.title,
        'status': g.status.name,
        if (g.targetDate != null) 'targetDate': g.targetDate!.toIso8601String(),
        if (progress != null) 'progressPercent': percent(progress.ratio),
      };

  /// Compact milestone view; adds `progress` when [progress] is given.
  static Map<String, dynamic> milestone(Milestone m,
          {MilestoneProgress? progress}) =>
      {
        'id': m.id,
        'goalId': m.goalId,
        'title': m.title,
        'isCompleted': m.isCompleted,
        if (m.dueDate != null) 'dueDate': m.dueDate!.toIso8601String(),
        'sortOrder': m.sortOrder,
        if (untrusted(m.description) != null)
          'description': untrusted(m.description),
        if (progress != null)
          'progress': {
            'percent': percent(progress.ratio),
            'completedTasks': progress.completedTasks,
            'totalTasks': progress.totalTasks,
            'isDone': progress.isDone,
          },
      };

  static Map<String, dynamic> project(Project p) => {
        'id': p.id,
        'title': p.title,
        'status': p.status.name,
        if (p.startDate != null) 'startDate': p.startDate!.toIso8601String(),
        if (p.targetDate != null) 'targetDate': p.targetDate!.toIso8601String(),
      };

  /// Compact course view; adds progress counters when [progress] is given.
  static Map<String, dynamic> course(Course c, {CourseProgress? progress}) => {
        'id': c.id,
        'title': c.title,
        'status': c.status.name,
        if (progress != null) ...{
          'progressPercent': percent(progress.ratio),
          'completedLessons': progress.completedLessons,
          'totalLessons': progress.totalLessons,
          'isDone': progress.isDone,
        },
      };

  /// 0.0…1.0 → rounded integer percent.
  static int percent(double ratio) => (ratio * 100).round();

  /// Marks [text] as untrusted data (see class doc). Returns null for blank
  /// text so callers can omit the field. When [maxLength] is given and the
  /// text is longer, it is cut and `truncated: true` is added.
  static Map<String, dynamic>? untrusted(String text, {int? maxLength}) {
    if (text.trim().isEmpty) return null;
    final cut = maxLength != null && text.length > maxLength;
    return {
      'untrusted': true,
      'text': cut ? text.substring(0, maxLength) : text,
      if (cut) 'truncated': true,
    };
  }

  /// A ≤[snippetLength]-char untrusted snippet of [text] around the first
  /// case-insensitive match of [query] (starting up to 60 chars before it), or
  /// from the start when there is no match. Null for blank text.
  static Map<String, dynamic>? snippet(String text, String query) {
    if (text.trim().isEmpty) return null;
    final idx =
        query.isEmpty ? -1 : text.toLowerCase().indexOf(query.toLowerCase());
    final start = idx < 0 ? 0 : math.max(0, idx - 60);
    final end = math.min(text.length, start + snippetLength);
    return {
      'untrusted': true,
      'text': text.substring(start, end),
      if (end < text.length) 'truncated': true,
    };
  }

  /// Plain text of an appflowy_editor document JSON (as stored in
  /// `Note.contentJson` / `Lesson.contentJson`): the `insert` strings of each
  /// node's `data.delta`, nodes joined by newlines, walked depth-first. Pure
  /// (no editor dependency). Invalid JSON or a non-document shape → the raw
  /// string trimmed.
  static String plainTextOfDoc(String contentJson) {
    final raw = contentJson.trim();
    if (raw.isEmpty) return '';
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return raw;
    }
    if (decoded is! Map || decoded['document'] is! Map) return raw;
    final lines = <String>[];
    void walk(Object? node) {
      if (node is! Map) return;
      final data = node['data'];
      if (data is Map && data['delta'] is List) {
        final b = StringBuffer();
        for (final op in data['delta'] as List) {
          if (op is Map && op['insert'] is String) b.write(op['insert']);
        }
        lines.add(b.toString());
      }
      final children = node['children'];
      if (children is List) {
        for (final c in children) {
          walk(c);
        }
      }
    }

    walk(decoded['document']);
    return lines.join('\n').trim();
  }

  static String? _time(dynamic timeOfDay) {
    if (timeOfDay == null) return null;
    final h = timeOfDay.hour as int;
    final m = timeOfDay.minute as int;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
