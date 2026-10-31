import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_project_item.dart';
import '../domain/repositories/calendar_repository.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/repositories/learning_repository.dart';
import '../domain/repositories/note_repository.dart';
import '../domain/repositories/task_list_repository.dart';
import '../domain/repositories/task_repository.dart';
import 'entity_picker.dart';

/// Hàm nạp danh sách [PickerEntry] cho một loại thực thể
/// ([ProjectEntityType]). Chỉ đọc (đồng bộ, qua `context.read`) đúng repository
/// cần thiết; loại không biết → danh sách rỗng.
Future<List<PickerEntry>> Function() entityLoader(
    BuildContext context, String entityType) {
  final icon = entityTypeIcon(entityType);
  switch (entityType) {
    case ProjectEntityType.taskList:
      final repo = context.read<TaskListRepository>();
      return () async => [
            for (final t in await repo.getTaskLists())
              PickerEntry(id: t.id, title: t.title, icon: icon),
          ];
    case ProjectEntityType.task:
      final repo = context.read<TaskRepository>();
      return () async => [
            for (final t in await repo.getTasks())
              PickerEntry(id: t.id, title: t.title, icon: icon),
          ];
    case ProjectEntityType.note:
      final repo = context.read<NoteRepository>();
      return () async => [
            for (final n in await repo.getNotes())
              PickerEntry(id: n.id, title: n.title, icon: icon),
          ];
    case ProjectEntityType.goal:
      final repo = context.read<GoalRepository>();
      return () async => [
            for (final g in await repo.getGoals())
              PickerEntry(id: g.id, title: g.title, icon: icon),
          ];
    case ProjectEntityType.calendarEvent:
      final repo = context.read<CalendarRepository>();
      final format = DateFormat('dd/MM/yyyy');
      return () async => [
            for (final e in await repo.getCalendarEvents())
              PickerEntry(
                id: e.id,
                title: e.title,
                subtitle: format.format(e.start.effective),
                icon: icon,
              ),
          ];
    case ProjectEntityType.course:
      final repo = context.read<LearningRepository>();
      return () async => [
            for (final c in await repo.getCourses())
              PickerEntry(id: c.id, title: c.title, icon: icon),
          ];
    default:
      return () async => const <PickerEntry>[];
  }
}

/// Biểu tượng cho một loại thực thể ([ProjectEntityType]).
IconData entityTypeIcon(String type) {
  switch (type) {
    case ProjectEntityType.taskList:
      return Icons.folder_outlined;
    case ProjectEntityType.task:
      return Icons.check_circle_outline;
    case ProjectEntityType.note:
      return Icons.notes_outlined;
    case ProjectEntityType.goal:
      return Icons.flag_outlined;
    case ProjectEntityType.calendarEvent:
      return Icons.event_outlined;
    case ProjectEntityType.course:
      return Icons.school_outlined;
    default:
      return Icons.link;
  }
}

/// Nhãn (số nhiều) cho một loại thực thể ([ProjectEntityType]).
String entityTypeLabel(AppLocalizations l, String type) {
  switch (type) {
    case ProjectEntityType.taskList:
      return l.projectSectionTaskLists;
    case ProjectEntityType.task:
      return l.projectSectionTasks;
    case ProjectEntityType.note:
      return l.projectSectionNotes;
    case ProjectEntityType.goal:
      return l.projectSectionGoals;
    case ProjectEntityType.calendarEvent:
      return l.projectSectionEvents;
    case ProjectEntityType.course:
      return l.courses;
    default:
      return type;
  }
}
