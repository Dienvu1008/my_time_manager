import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/services/project_workspace_service.dart';
import 'project_labels.dart';

/// Màn không gian làm việc của một dự án (Core Track C6) — CHỈ ĐỌC. Hiển thị
/// read model [ProjectWorkspace] (suy ra bởi [ProjectWorkspaceService], không
/// lưu) theo các mục: danh sách, công việc, ghi chú, mục tiêu, sự kiện lịch.
class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  late final ProjectWorkspaceService _service =
      context.read<ProjectWorkspaceService>();
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
            child: _WorkspaceView(ws: ws, l: l),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          body: body,
        );
      },
    );
  }
}

class _WorkspaceView extends StatelessWidget {
  const _WorkspaceView({required this.ws, required this.l});

  final ProjectWorkspace ws;
  final AppLocalizations l;

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
      padding: const EdgeInsets.only(bottom: 24),
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
