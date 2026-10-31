import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_goal.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/services/goal_progress_service.dart';
import '../screen_learning/learning_labels.dart';
import '../screen_projects/project_labels.dart';
import 'goal_detail_screen.dart';
import 'goal_form_screen.dart';
import 'goal_labels.dart';

/// Màn danh sách Mục tiêu. Mở dạng route đẩy từ drawer; đọc [GoalRepository]
/// / [GoalProgressService] qua provider. Tiến độ mỗi mục tiêu là giá trị suy
/// ra (không lưu). Lọc theo trạng thái phía client (mặc định: tất cả).
class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  late final GoalRepository _repository = context.read<GoalRepository>();
  late final GoalProgressService _progress =
      context.read<GoalProgressService>();
  late Future<(List<Goal>, Map<String, GoalProgress?>)> _future;

  /// null = tất cả trạng thái.
  GoalStatus? _filter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<(List<Goal>, Map<String, GoalProgress?>)> _load() async {
    final goals = await _repository.getGoals();
    final progress = <String, GoalProgress?>{
      for (final g in goals) g.id: await _progress.progressOf(g.id),
    };
    return (goals, progress);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
    );
    if (created == true && mounted) await _refresh();
  }

  Widget _filterChips(AppLocalizations l) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l.goalFilterAll),
            selected: _filter == null,
            onSelected: (_) => setState(() => _filter = null),
          ),
          for (final s in GoalStatus.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(goalStatusLabel(l, s)),
              selected: _filter == s,
              onSelected: (_) => setState(() => _filter = s),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.goals)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.newGoal,
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<(List<Goal>, Map<String, GoalProgress?>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l.error}: ${snapshot.error}'));
          }
          final (goals, progress) = snapshot.data ??
              (const <Goal>[], const <String, GoalProgress?>{});
          if (goals.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [_EmptyState(l: l)],
              ),
            );
          }
          final filter = _filter;
          final visible = filter == null
              ? goals
              : goals.where((g) => g.status == filter).toList();
          return Column(
            children: [
              _filterChips(l),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: visible.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                l.noGoalsForFilter,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              _tile(context, l, visible[index],
                                  progress[visible[index].id]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
      BuildContext context, AppLocalizations l, Goal g, GoalProgress? p) {
    final ratio = p?.ratio ?? 0.0;
    final percent = formatPercent(ratio);
    final target = g.targetDate;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: g.color,
        child: const ExcludeSemantics(child: Icon(Icons.flag_outlined)),
      ),
      title: Text(
        g.title.isEmpty ? l.projectUntitled : g.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goalStatusLabel(l, g.status) +
              (target != null
                  ? ' · ${l.goalTargetDate}: ${formatProjectDate(target)}'
                  : '')),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ratio,
            semanticsLabel: l.projectGoalProgress,
            semanticsValue: percent,
          ),
        ],
      ),
      trailing: Text(percent),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GoalDetailScreen(goalId: g.id),
          ),
        );
        if (mounted) await _refresh();
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 48, semanticLabel: l.goals),
          const SizedBox(height: 16),
          Text(l.noGoalsYet,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.noGoalsHint,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
