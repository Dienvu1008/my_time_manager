import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_project.dart';
import '../domain/models/model_project_item.dart';
import '../domain/repositories/project_repository.dart';
import '../domain/services/project_workspace_service.dart';
import '../shared/confirm_dialog.dart';
import '../shared/entity_picker.dart';
import '../shared/entity_picker_sources.dart';
import 'project_form_screen.dart';
import 'project_labels.dart';

/// Màn không gian làm việc của một dự án (Core Track C6). Hiển thị read model
/// [ProjectWorkspace] (suy ra bởi [ProjectWorkspaceService], không lưu) theo
/// các mục: danh sách, công việc, ghi chú, mục tiêu, khóa học, sự kiện lịch.
/// Cho phép sửa / lưu trữ / chuyển dự án vào thùng rác, thêm mục (chọn loại →
/// chọn thực thể) và gỡ mục (chỉ gỡ liên kết, không xóa thực thể). Task chỉ
/// thuộc dự án gián tiếp qua danh sách không có nút gỡ.
class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

enum _ProjectAction { archive, trash }

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  late final ProjectWorkspaceService _service =
      context.read<ProjectWorkspaceService>();
  // Lazy: chỉ đọc trong các callback (thêm / gỡ mục, lưu trữ, thùng rác).
  late final ProjectRepository _projects = context.read<ProjectRepository>();
  late Future<ProjectWorkspace?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _service.workspaceOf(widget.projectId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  /// Chạy [action]; nếu lỗi thì hiện SnackBar và trả về false.
  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
      return false;
    }
  }

  Future<void> _editProject(Project project) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProjectFormScreen(project: project)),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _onProjectAction(
      AppLocalizations l, _ProjectAction action) async {
    final bool ok;
    switch (action) {
      case _ProjectAction.archive:
        if (!await showConfirmDialog(context,
            message: l.confirmArchiveProject, confirmLabel: l.archive)) {
          return;
        }
        ok = await _guard(() => _projects.archiveProject(widget.projectId));
      case _ProjectAction.trash:
        if (!await showConfirmDialog(context,
            message: l.confirmTrashProject, confirmLabel: l.moveToTrash)) {
          return;
        }
        ok = await _guard(
            () => _projects.softDeleteProject(widget.projectId));
    }
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _addItem(AppLocalizations l) async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.projectChooseItemType),
        children: [
          for (final t in ProjectEntityType.supported)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(entityTypeIcon(t))),
                  const SizedBox(width: 16),
                  Text(entityTypeLabel(l, t)),
                ],
              ),
            ),
        ],
      ),
    );
    if (type == null || !mounted) return;
    // Đọc repository cần thiết trước các await kế tiếp.
    final load = entityLoader(context, type);
    final items = await _projects.getItems(widget.projectId);
    if (!mounted) return;
    final entry = await Navigator.of(context).push<PickerEntry>(
      MaterialPageRoute(
        builder: (_) => EntityPickerScreen(
          title: entityTypeLabel(l, type),
          load: load,
          excludeIds: {
            for (final i in items)
              if (i.entityType == type) i.entityId,
          },
        ),
      ),
    );
    if (entry == null) return;
    final ok = await _guard(() => _projects.addItem(
        widget.projectId, type, entry.id,
        sortOrder: items.length));
    if (ok && mounted) await _refresh();
  }

  Future<void> _removeItem(
      AppLocalizations l, String type, String entityId) async {
    if (!await showConfirmDialog(context,
        message: l.confirmRemoveProjectItem, confirmLabel: l.removeItem)) {
      return;
    }
    final ok = await _guard(
        () => _projects.removeEntity(widget.projectId, type, entityId));
    if (ok && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<ProjectWorkspace?>(
      future: _future,
      builder: (context, snapshot) {
        final ws = snapshot.data;
        final title = ws == null
            ? l.projectWorkspace
            : (ws.project.title.isEmpty ? l.projectUntitled : ws.project.title);
        Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          body = Center(child: Text('${l.error}: ${snapshot.error}'));
        } else if (ws == null) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.projectNotFound,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          );
        } else {
          body = RefreshIndicator(
            onRefresh: _refresh,
            child: _WorkspaceView(
              ws: ws,
              l: l,
              onRemove: (String type, String entityId) =>
                  _removeItem(l, type, entityId),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              if (ws != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l.editProject,
                  onPressed: () => _editProject(ws.project),
                ),
                PopupMenuButton<_ProjectAction>(
                  onSelected: (a) => _onProjectAction(l, a),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: _ProjectAction.archive, child: Text(l.archive)),
                    PopupMenuItem(
                        value: _ProjectAction.trash,
                        child: Text(l.moveToTrash)),
                  ],
                ),
              ],
            ],
          ),
          floatingActionButton: ws == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addItem(l),
                  tooltip: l.projectAddItem,
                  icon: const Icon(Icons.add),
                  label: Text(l.projectAddItem),
                ),
          body: body,
        );
      },
    );
  }
}

class _WorkspaceView extends StatelessWidget {
  const _WorkspaceView({
    required this.ws,
    required this.l,
    required this.onRemove,
  });

  final ProjectWorkspace ws;
  final AppLocalizations l;

  /// Gỡ mục (entityType, entityId) khỏi dự án (chỉ liên kết).
  final void Function(String type, String entityId) onRemove;

  Widget _removeButton(String type, String entityId) => IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        tooltip: l.removeItem,
        onPressed: () => onRemove(type, entityId),
      );

  String _listTitle(String? id) {
    for (final list in ws.taskLists) {
      if (list.id == id) {
        return list.title.isEmpty ? l.projectUntitled : list.title;
      }
    }
    return l.projectUntitled;
  }

  String _orUntitled(String s) => s.isEmpty ? l.projectUntitled : s;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Chừa chỗ cho FAB "Thêm mục".
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _Header(ws: ws, l: l),
        _Section(
          title: l.projectSectionTaskLists,
          emptyText: l.projectSectionEmpty,
          children: [
            for (final list in ws.taskLists)
              ListTile(
                leading: const ExcludeSemantics(
                    child: Icon(Icons.folder_outlined)),
                title: Text(_orUntitled(list.title)),
                trailing: _removeButton(ProjectEntityType.taskList, list.id),
              ),
          ],
        ),
        _Section(
          title: l.projectSectionTasks,
          emptyText: l.projectSectionEmpty,
          children: [
            for (final t in ws.tasks)
              ListTile(
                leading: Icon(
                  t.task.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  semanticLabel: t.task.isCompleted
                      ? l.projectTaskCompleted
                      : l.projectTaskNotCompleted,
                ),
                title: Text(_orUntitled(t.task.title)),
                subtitle: Text([
                  if (t.isViaTaskList)
                    '${l.projectViaList}: ${_listTitle(t.viaTaskListId)}',
                  if (t.isDirect) l.projectLinkedDirectly,
                ].join(' · ')),
                // Task chỉ thuộc gián tiếp (qua danh sách) không có item để gỡ.
                trailing: t.isDirect
                    ? _removeButton(ProjectEntityType.task, t.task.id)
                    : null,
              ),
          ],
        ),
        _Section(
          title: l.projectSectionNotes,
          emptyText: l.projectSectionEmpty,
          children: [
            for (final n in ws.notes)
              ListTile(
                leading:
                    const ExcludeSemantics(child: Icon(Icons.notes_outlined)),
                title: Text(_orUntitled(n.title)),
                trailing: _removeButton(ProjectEntityType.note, n.id),
              ),
          ],
        ),
        _Section(
          title: l.projectSectionGoals,
          emptyText: l.projectSectionEmpty,
          children: [
            for (final g in ws.goals) _goalTile(context, g),
          ],
        ),
        // Khóa học (Core Track C7) — tiến độ suy ra, chỉ đọc.
        _Section(
          title: l.courses,
          emptyText: l.projectSectionEmpty,
          children: [
            for (final c in ws.courses) _courseTile(context, c),
          ],
        ),
        // Thói quen (Phase H3) — chuỗi hiện tại suy ra, chỉ đọc.
        _Section(
          title: l.habits,
          emptyText: l.projectSectionEmpty,
          children: [
            for (final h in ws.habits) _habitTile(context, h),
          ],
        ),
        _Section(
          title: l.projectSectionEvents,
          emptyText: l.projectSectionEmpty,
          children: [
            for (final e in ws.calendarEvents)
              ListTile(
                leading:
                    const ExcludeSemantics(child: Icon(Icons.event_outlined)),
                title: Text(_orUntitled(e.title)),
                subtitle: Text(formatProjectDate(e.start.effective)),
                trailing: _removeButton(ProjectEntityType.calendarEvent, e.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _goalTile(BuildContext context, WorkspaceGoal g) {
    final ratio = g.progress?.ratio ?? 0.0;
    final percent = '${(ratio * 100).round()}%';
    return ListTile(
      leading: const ExcludeSemantics(child: Icon(Icons.flag_outlined)),
      title: Text(_orUntitled(g.goal.title)),
      subtitle: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              semanticsLabel: l.projectGoalProgress,
              semanticsValue: percent,
            ),
          ),
          const SizedBox(width: 8),
          Text(percent, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: _removeButton(ProjectEntityType.goal, g.goal.id),
    );
  }

  Widget _habitTile(BuildContext context, WorkspaceHabit h) {
    return ListTile(
      key: ValueKey('project-habit-${h.habit.id}'),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: h.habit.color,
        child: const ExcludeSemantics(child: Icon(Icons.repeat, size: 16)),
      ),
      title: Text(_orUntitled(h.habit.title)),
      subtitle:
          Text(l.habitStreakChip.replaceAll('{n}', '${h.currentStreak}')),
      trailing: _removeButton(ProjectEntityType.habit, h.habit.id),
    );
  }

  Widget _courseTile(BuildContext context, WorkspaceCourse c) {
    final ratio = c.progress?.ratio ?? 0.0;
    final percent = '${(ratio * 100).round()}%';
    return ListTile(
      leading: const ExcludeSemantics(child: Icon(Icons.school_outlined)),
      title: Text(_orUntitled(c.course.title)),
      subtitle: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              semanticsLabel: l.learningProgress,
              semanticsValue: percent,
            ),
          ),
          const SizedBox(width: 8),
          Text(percent, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: _removeButton(ProjectEntityType.course, c.course.id),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ws, required this.l});

  final ProjectWorkspace ws;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = ws.project;
    final ratio = ws.taskCompletionRatio;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description.isNotEmpty) ...[
              Text(project.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            Text(projectStatusLabel(l, project.status),
                style: theme.textTheme.labelLarge),
            if (project.startDate != null)
              Text(
                  '${l.projectStartDate}: ${formatProjectDate(project.startDate!)}',
                  style: theme.textTheme.bodySmall),
            if (project.targetDate != null)
              Text(
                  '${l.projectTargetDate}: ${formatProjectDate(project.targetDate!)}',
                  style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(
                '${l.projectTasksCompleted}: ${ws.completedTasks}/${ws.totalTasks}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: ratio,
              semanticsLabel: l.projectTasksCompleted,
              semanticsValue: '${(ratio * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
        ),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(emptyText, style: theme.textTheme.bodyMedium),
          )
        else
          ...children,
      ],
    );
  }
}
