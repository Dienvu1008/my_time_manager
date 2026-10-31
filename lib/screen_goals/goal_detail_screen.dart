import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_course.dart';
import '../domain/models/model_goal.dart';
import '../domain/models/model_goal_link.dart';
import '../domain/models/model_milestone.dart';
import '../domain/models/model_project_item.dart';
import '../domain/models/model_task.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/repositories/learning_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/services/goal_progress_service.dart';
import '../screen_learning/learning_labels.dart';
import '../screen_projects/project_labels.dart';
import '../shared/confirm_dialog.dart';
import '../shared/date_field.dart';
import '../shared/entity_picker.dart';
import '../shared/entity_picker_sources.dart';
import 'goal_form_screen.dart';
import 'goal_labels.dart';

/// Màn chi tiết một mục tiêu: tiến độ suy ra, các cột mốc (thêm / sửa / xóa /
/// đánh dấu xong / sắp xếp lên-xuống), các task / khóa học được gắn (theo cột
/// mốc hoặc gắn trực tiếp), gắn / bỏ gắn, sửa / lưu trữ / chuyển vào thùng rác.
///
/// Chỉ hiển thị liên kết tới thực thể "sống" (còn trong getTasks / getCourses),
/// khớp với quy tắc tính tiến độ của [GoalProgressService].
class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalData {
  const _GoalData({
    required this.goal,
    required this.milestones,
    required this.links,
    required this.progress,
    required this.milestoneProgress,
    required this.tasksById,
    required this.coursesById,
  });

  final Goal goal;
  final List<Milestone> milestones;
  final List<GoalLink> links;
  final GoalProgress? progress;
  final Map<String, MilestoneProgress> milestoneProgress;
  final Map<String, Task> tasksById;
  final Map<String, Course> coursesById;

  /// Liên kết tới thực thể sống thuộc [milestoneId] (null = gắn trực tiếp).
  List<GoalLink> visibleLinks(String? milestoneId) => [
        for (final link in links)
          if (link.milestoneId == milestoneId &&
              ((link.entityType == GoalEntityType.task &&
                      tasksById.containsKey(link.entityId)) ||
                  (link.entityType == GoalEntityType.course &&
                      coursesById.containsKey(link.entityId))))
            link,
      ];
}

enum _MilestoneAction { edit, moveUp, moveDown, delete }

enum _GoalAction { archive, trash }

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late final GoalRepository _repository = context.read<GoalRepository>();
  late final GoalProgressService _progress =
      context.read<GoalProgressService>();
  late final TaskRepository _tasks = context.read<TaskRepository>();
  late final LearningRepository _learning =
      context.read<LearningRepository>();
  late Future<_GoalData?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_GoalData?> _load() async {
    final goal = await _repository.getGoal(widget.goalId);
    if (goal == null) return null;
    final milestones = await _repository.getMilestones(goal.id);
    final links = await _repository.getLinks(goal.id);
    final progress = await _progress.progressOf(goal.id);
    final tasks = await _tasks.getTasks();
    final courses = await _learning.getCourses();
    return _GoalData(
      goal: goal,
      milestones: milestones,
      links: links,
      progress: progress,
      milestoneProgress: {
        for (final p in progress?.milestones ?? const <MilestoneProgress>[])
          p.milestoneId: p,
      },
      tasksById: {for (final t in tasks) t.id: t},
      coursesById: {for (final c in courses) c.id: c},
    );
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

  // ---------------- Goal actions ----------------

  Future<void> _editGoal(Goal goal) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GoalFormScreen(goal: goal)),
    );
    if (mounted) await _refresh();
  }

  Future<void> _onGoalAction(AppLocalizations l, _GoalAction action) async {
    final bool ok;
    switch (action) {
      case _GoalAction.archive:
        if (!await showConfirmDialog(context,
            message: l.confirmArchiveGoal, confirmLabel: l.archive)) {
          return;
        }
        ok = await _guard(() => _repository.archiveGoal(widget.goalId));
      case _GoalAction.trash:
        if (!await showConfirmDialog(context,
            message: l.confirmTrashGoal, confirmLabel: l.moveToTrash)) {
          return;
        }
        ok = await _guard(() => _repository.softDeleteGoal(widget.goalId));
    }
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  // ---------------- Milestone actions ----------------

  Future<(String, DateTime?)?> _showMilestoneDialog(
      AppLocalizations l, Milestone? milestone) {
    return showDialog<(String, DateTime?)>(
      context: context,
      builder: (_) => _MilestoneDialog(
        title: milestone == null ? l.newMilestone : l.editMilestone,
        initialTitle: milestone?.title ?? '',
        initialDueDate: milestone?.dueDate,
      ),
    );
  }

  Future<void> _addMilestone(AppLocalizations l, _GoalData data) async {
    final result = await _showMilestoneDialog(l, null);
    if (result == null) return;
    // max(sortOrder) + 1: sau khi xóa để lại khoảng trống, count có thể trùng
    // sortOrder của cột mốc cuối.
    final nextOrder = data.milestones.isEmpty
        ? 0
        : data.milestones.map((m) => m.sortOrder).reduce(max) + 1;
    if (!await _guard(() => _repository.createMilestone(Milestone(
          goalId: data.goal.id,
          title: result.$1,
          dueDate: result.$2,
          sortOrder: nextOrder,
        )))) {
      return;
    }
    if (mounted) await _refresh();
  }

  Future<void> _toggleMilestone(Milestone m, bool? value) async {
    if (!await _guard(
        () => _repository.setMilestoneCompleted(m.id, value ?? false))) {
      return;
    }
    if (mounted) await _refresh();
  }

  Future<void> _onMilestoneAction(AppLocalizations l, _GoalData data,
      Milestone milestone, _MilestoneAction action) async {
    final bool ok;
    switch (action) {
      case _MilestoneAction.edit:
        final result = await _showMilestoneDialog(l, milestone);
        if (result == null) return;
        ok = await _guard(() => _repository.updateMilestone(milestone.copyWith(
              title: result.$1,
              dueDate: result.$2,
              clearDueDate: result.$2 == null,
              updateTimeStamp: DateTime.now(),
            )));
      case _MilestoneAction.moveUp:
      case _MilestoneAction.moveDown:
        final ids = [for (final m in data.milestones) m.id];
        if (!_swap(ids, milestone.id, action == _MilestoneAction.moveUp)) {
          return;
        }
        ok = await _guard(
            () => _repository.reorderMilestones(data.goal.id, ids));
      case _MilestoneAction.delete:
        if (!await showConfirmDialog(context,
            message: l.confirmDeleteMilestone, confirmLabel: l.delete)) {
          return;
        }
        ok = await _guard(() => _repository.deleteMilestone(milestone.id));
    }
    if (ok && mounted) await _refresh();
  }

  /// Đổi chỗ [id] với phần tử liền trước / liền sau. false nếu không đổi được.
  static bool _swap(List<String> ids, String id, bool up) {
    final i = ids.indexOf(id);
    final j = up ? i - 1 : i + 1;
    if (i < 0 || j < 0 || j >= ids.length) return false;
    final tmp = ids[i];
    ids[i] = ids[j];
    ids[j] = tmp;
    return true;
  }

  // ---------------- Link actions ----------------

  /// Chọn một task / khóa học rồi (nếu có cột mốc) chọn đích gắn.
  Future<void> _link(
      AppLocalizations l, _GoalData data, String entityType) async {
    // Đọc loader trước mọi await (dùng context đồng bộ).
    final load = entityLoader(context, entityType);
    final isTask = entityType == ProjectEntityType.task;
    final entry = await Navigator.of(context).push<PickerEntry>(
      MaterialPageRoute(
        builder: (_) => EntityPickerScreen(
          title: isTask ? l.goalLinkTask : l.goalLinkCourse,
          load: load,
          excludeIds: {
            for (final link in data.links)
              if (link.entityType == entityType) link.entityId,
          },
        ),
      ),
    );
    if (entry == null || !mounted) return;
    String? target;
    if (data.milestones.isNotEmpty) {
      // Record bọc id để phân biệt "gắn trực tiếp" (id null) với đóng hộp
      // thoại (kết quả null).
      final choice = await showDialog<({String? id})>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l.goalLinkTarget),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, (id: null)),
              child: Text(l.goalLinkDirect),
            ),
            for (final m in data.milestones)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, (id: m.id)),
                child: Text(m.title.isEmpty ? l.projectUntitled : m.title),
              ),
          ],
        ),
      );
      if (choice == null) return;
      target = choice.id;
    }
    final ok = await _guard(() async {
      if (isTask) {
        await _repository.linkTask(data.goal.id, entry.id,
            milestoneId: target);
      } else {
        await _repository.linkCourse(data.goal.id, entry.id,
            milestoneId: target);
      }
    });
    if (ok && mounted) await _refresh();
  }

  Future<void> _unlink(AppLocalizations l, GoalLink link) async {
    if (!await showConfirmDialog(context,
        message: l.confirmUnlink, confirmLabel: l.goalUnlink)) {
      return;
    }
    final ok = await _guard(() async {
      if (link.entityType == GoalEntityType.task) {
        await _repository.unlinkTask(link.goalId, link.entityId);
      } else {
        await _repository.unlinkCourse(link.goalId, link.entityId);
      }
    });
    if (ok && mounted) await _refresh();
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<_GoalData?>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.goals)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(l.goals)),
            body: Center(child: Text('${l.error}: ${snapshot.error}')),
          );
        }
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.goals)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.goalNotFound,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          );
        }
        final goal = data.goal;
        final theme = Theme.of(context);
        final direct = data.visibleLinks(null);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              goal.title.isEmpty ? l.projectUntitled : goal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.editGoal,
                onPressed: () => _editGoal(goal),
              ),
              PopupMenuButton<_GoalAction>(
                onSelected: (a) => _onGoalAction(l, a),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: _GoalAction.archive, child: Text(l.archive)),
                  PopupMenuItem(
                      value: _GoalAction.trash, child: Text(l.moveToTrash)),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Header(
                  goal: goal,
                  progress: data.progress,
                  hasMilestones: data.milestones.isNotEmpty,
                  l: l,
                ),
                // --- Milestones ---
                _sectionHeader(theme, l.goalMilestones),
                if (data.milestones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l.noMilestonesYet,
                        style: theme.textTheme.bodyMedium),
                  ),
                for (var i = 0; i < data.milestones.length; i++)
                  _milestoneCard(l, data, i),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addMilestone(l, data),
                      icon: const Icon(Icons.add),
                      label: Text(l.addMilestone),
                    ),
                  ),
                ),
                // --- Linked directly ---
                _sectionHeader(theme, l.projectLinkedDirectly),
                if (direct.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l.projectSectionEmpty,
                        style: theme.textTheme.bodyMedium),
                  ),
                for (final link in direct) _linkRow(l, data, link),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _link(l, data, ProjectEntityType.task),
                        icon: const Icon(Icons.add_task),
                        label: Text(l.goalLinkTask),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _link(l, data, ProjectEntityType.course),
                        icon: const Icon(Icons.school_outlined),
                        label: Text(l.goalLinkCourse),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleMedium),
      ),
    );
  }

  Widget _milestoneCard(AppLocalizations l, _GoalData data, int index) {
    final m = data.milestones[index];
    final p = data.milestoneProgress[m.id];
    final due = m.dueDate;
    final linked = data.visibleLinks(m.id);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Checkbox(
              value: m.isCompleted,
              semanticLabel: l.markComplete,
              onChanged: (v) => _toggleMilestone(m, v),
            ),
            title: Text(m.title.isEmpty ? l.projectUntitled : m.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (due != null)
                  Text('${l.milestoneDueDate}: ${formatProjectDate(due)}'),
                Text('${l.projectTasksCompleted}: '
                    '${p?.completedTasks ?? 0}/${p?.totalTasks ?? 0}'
                    ' · ${formatPercent(p?.ratio ?? 0.0)}'),
              ],
            ),
            trailing: PopupMenuButton<_MilestoneAction>(
              onSelected: (a) => _onMilestoneAction(l, data, m, a),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: _MilestoneAction.edit,
                    child: Text(l.editMilestone)),
                if (index > 0)
                  PopupMenuItem(
                      value: _MilestoneAction.moveUp, child: Text(l.moveUp)),
                if (index < data.milestones.length - 1)
                  PopupMenuItem(
                      value: _MilestoneAction.moveDown,
                      child: Text(l.moveDown)),
                PopupMenuItem(
                    value: _MilestoneAction.delete, child: Text(l.delete)),
              ],
            ),
          ),
          for (final link in linked) _linkRow(l, data, link),
        ],
      ),
    );
  }

  Widget _linkRow(AppLocalizations l, _GoalData data, GoalLink link) {
    final unlink = IconButton(
      icon: const Icon(Icons.link_off),
      tooltip: l.goalUnlink,
      onPressed: () => _unlink(l, link),
    );
    if (link.entityType == GoalEntityType.task) {
      final t = data.tasksById[link.entityId]!;
      return ListTile(
        leading: Icon(
          t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          semanticLabel: t.isCompleted
              ? l.projectTaskCompleted
              : l.projectTaskNotCompleted,
        ),
        title: Text(t.title.isEmpty ? l.projectUntitled : t.title),
        trailing: unlink,
      );
    }
    final c = data.coursesById[link.entityId]!;
    return ListTile(
      leading: const ExcludeSemantics(child: Icon(Icons.school_outlined)),
      title: Text(c.title.isEmpty ? l.projectUntitled : c.title),
      trailing: unlink,
    );
  }
}

/// Hộp thoại tiêu đề (bắt buộc) + hạn của cột mốc. Sở hữu controller của nó.
/// Trả về (title, dueDate).
class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog({
    required this.title,
    this.initialTitle = '',
    this.initialDueDate,
  });

  final String title;
  final String initialTitle;
  final DateTime? initialDueDate;

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.initialTitle);
  late DateTime? _due = widget.initialDueDate;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, (_title.text.trim(), _due));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(labelText: l.title),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.titleRequired : null,
            ),
            const SizedBox(height: 16),
            DateField(
              label: l.milestoneDueDate,
              value: _due,
              onChanged: (d) => setState(() => _due = d),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.goal,
    required this.progress,
    required this.hasMilestones,
    required this.l,
  });

  final Goal goal;
  final GoalProgress? progress;
  final bool hasMilestones;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = progress?.ratio ?? 0.0;
    final percent = formatPercent(ratio);
    final target = goal.targetDate;
    final p = progress;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (goal.description.isNotEmpty) ...[
              Text(goal.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            Text(goalStatusLabel(l, goal.status),
                style: theme.textTheme.labelLarge),
            if (target != null) ...[
              const SizedBox(height: 4),
              Text('${l.goalTargetDate}: ${formatProjectDate(target)}',
                  style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: ratio,
                    semanticsLabel: l.projectGoalProgress,
                    semanticsValue: percent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(percent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasMilestones
                  ? '${l.goalMilestonesDone}: '
                      '${p?.doneMilestones ?? 0}/${p?.totalMilestones ?? 0}'
                  : '${l.projectTasksCompleted}: '
                      '${p?.directCompletedTasks ?? 0}/${p?.directTotalTasks ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
