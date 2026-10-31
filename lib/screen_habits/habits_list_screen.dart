import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_habit.dart';
import '../domain/models/model_habit_occurrence.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/services/habit_statistics_service.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';
import 'habit_labels.dart';

/// Active habits with today's state and quick check-in (Phase H2). Pushed
/// from the drawer; reads [HabitRepository] / [HabitStatisticsService] via
/// provider. Streaks and today's state are derived (nothing is stored).
class HabitsListScreen extends StatefulWidget {
  const HabitsListScreen({super.key, this.now});

  /// Injectable clock (tests). Defaults to [DateTime.now].
  final DateTime Function()? now;

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

/// One list row: a habit, its statistics for today and whether today is
/// scheduled under the current rule.
class _HabitRow {
  const _HabitRow(this.habit, this.stats, this.scheduledToday);

  final Habit habit;
  final HabitStatistics stats;
  final bool scheduledToday;

  /// Today's resolved day (scheduled or recorded), or null.
  ResolvedHabitDay? get today {
    for (final d in stats.days) {
      if (d.day == stats.today) return d;
    }
    return null;
  }
}

class _HabitsListScreenState extends State<HabitsListScreen> {
  late final HabitRepository _repository = context.read<HabitRepository>();
  late final HabitStatisticsService _statistics =
      context.read<HabitStatisticsService>();
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  late Future<List<_HabitRow>> _future;

  /// Habit ids with a quick action in flight (buttons disabled).
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<List<_HabitRow>> _load() async {
    final now = _now();
    final today = HabitDay.of(now);
    final habits = await _repository.getHabits();
    return [
      for (final h in habits)
        _HabitRow(
          h,
          _statistics.compute(h, await _repository.occurrencesOf(h.id),
              now: now, from: today, to: today),
          h.isScheduledOn(today),
        ),
    ];
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => HabitFormScreen(now: widget.now)),
    );
    if (created == true && mounted) await _refresh();
  }

  /// Record [outcome] for today, or clear today's record when null.
  Future<void> _quick(Habit habit, HabitOutcome? outcome) async {
    if (_busy.contains(habit.id)) return;
    setState(() => _busy.add(habit.id));
    final today = HabitDay.of(_now());
    try {
      if (outcome == null) {
        await _repository.clearOutcome(habit.id, today);
      } else {
        await _repository.recordOutcome(habit.id, today, outcome);
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(habit.id));
    }
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.habits)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.newHabit,
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<_HabitRow>>(
        future: _future,
        builder: (context, snapshot) {
          final rows = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting &&
              rows == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l.error}: ${snapshot.error}'));
          }
          final list = rows ?? const <_HabitRow>[];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [_EmptyState(l: l, onCreate: _create)],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
              itemCount: list.length,
              itemBuilder: (context, index) => _tile(context, l, list[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, AppLocalizations l, _HabitRow row) {
    final habit = row.habit;
    final today = row.today;
    final busy = _busy.contains(habit.id);
    final recorded = today?.isRecorded ?? false;
    final stateText = today == null
        ? l.habitNotScheduledToday
        : l.habitTodayState
            .replaceAll('{state}', habitOutcomeLabel(l, today.outcome));
    final streak = row.stats.currentStreak;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: habit.color,
              child: const ExcludeSemantics(child: Icon(Icons.repeat)),
            ),
            title: Text(
              habit.title.isEmpty ? l.projectUntitled : habit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Semantics(
                    label: '${l.habitCurrentStreak}: $streak',
                    excludeSemantics: true,
                    child: Chip(
                      key: ValueKey('streak-${habit.id}'),
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.local_fire_department, size: 18),
                      label: Text(
                          l.habitStreakChip.replaceAll('{n}', '$streak')),
                    ),
                  ),
                  if (today != null)
                    HabitOutcomeIcon(
                        outcome: today.outcome,
                        isRecorded: today.isRecorded,
                        size: 20),
                  Text(stateText),
                ],
              ),
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      HabitDetailScreen(habitId: habit.id, now: widget.now),
                ),
              );
              if (mounted) await _refresh();
            },
          ),
          if (row.scheduledToday || recorded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (row.scheduledToday) ...[
                    _action(
                      icon: Icons.check_circle_outline,
                      tooltip: l.habitMarkComplete,
                      selected: recorded &&
                          today!.outcome == HabitOutcome.completed,
                      onPressed: busy
                          ? null
                          : () => _quick(habit, HabitOutcome.completed),
                    ),
                    _action(
                      icon: Icons.timelapse,
                      tooltip: l.habitMarkPartial,
                      selected:
                          recorded && today!.outcome == HabitOutcome.partial,
                      onPressed: busy
                          ? null
                          : () => _quick(habit, HabitOutcome.partial),
                    ),
                    _action(
                      icon: Icons.skip_next_outlined,
                      tooltip: l.habitMarkSkip,
                      selected:
                          recorded && today!.outcome == HabitOutcome.skipped,
                      onPressed: busy
                          ? null
                          : () => _quick(habit, HabitOutcome.skipped),
                    ),
                  ],
                  if (recorded)
                    _action(
                      icon: Icons.undo,
                      tooltip: l.habitUndoToday,
                      selected: false,
                      onPressed: busy ? null : () => _quick(habit, null),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback? onPressed,
  }) {
    // IconButton keeps the 48x48 minimum tap target.
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l, required this.onCreate});

  final AppLocalizations l;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(child: Icon(Icons.repeat, size: 48)),
          const SizedBox(height: 16),
          Text(l.noHabitsYet,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.noHabitsHint,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l.habitCreateFirst),
          ),
        ],
      ),
    );
  }
}
