import '../../../data/models/model_calendar_event.dart';
import '../../../data/models/model_task.dart';
import '../../../data/models/model_time_interval.dart';

/// Compact, deterministic JSON views of domain models for tool results. These
/// are intentionally smaller than the full model maps: they expose only the
/// fields an agent needs to reason about, avoiding noisy/large prompts.
class ToolViews {
  const ToolViews._();

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

  static String? _time(dynamic timeOfDay) {
    if (timeOfDay == null) return null;
    final h = timeOfDay.hour as int;
    final m = timeOfDay.minute as int;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
