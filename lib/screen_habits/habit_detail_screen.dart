import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_habit.dart';
import '../domain/models/model_habit_occurrence.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/services/habit_statistics_service.dart';
import '../screen_learning/learning_labels.dart';
import '../shared/confirm_dialog.dart';
import 'habit_form_screen.dart';
import 'habit_labels.dart';

/// Detail of one habit (Phase H2): header, derived statistics (streaks,
/// completion rate, counts per outcome) and the last 30 days of resolved days.
/// Tapping a day (≤ today) records / clears its outcome; changing a PAST day
/// asks for confirmation. AppBar menu: edit, archive, delete permanently.
/// Pops `true` after archive / permanent delete.
class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId, this.now});

  final String habitId;

  /// Injectable clock (tests). Defaults to [DateTime.now].
  final DateTime Function()? now;

  /// Number of days (including today) shown in the history.
  static const historyDays = 30;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitData {
  const _HabitData(this.habit, this.stats, this.history);

  final Habit habit;
  final HabitStatistics stats;

  /// Resolved days of the last [HabitDetailScreen.historyDays] days, newest
  /// first.
  final List<ResolvedHabitDay> history;
}

enum _HabitAction { edit, archive, delete }

/// Result of the day sheet: record [outcome] (with [amount] / [note]) or
/// [clear] the record.
class _DayEdit {
  const _DayEdit.record(this.outcome, {this.amount, this.note}) : clear = false;
  const _DayEdit.clear()
      : outcome = null,
        amount = null,
        note = null,
        clear = true;

  final HabitOutcome? outcome;
  final double? amount;
  final String? note;
  final bool clear;
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late final HabitRepository _repository = context.read<HabitRepository>();
  late final HabitStatisticsService _statistics =
      context.read<HabitStatisticsService>();
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  late Future<_HabitData?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_HabitData?> _load() async {
    final habit = await _repository.getHabit(widget.habitId);
    if (habit == null) return null;
    final now = _now();
    final today = HabitDay.of(now);
    final occurrences = await _repository.occurrencesOf(habit.id);
    final stats = _statistics.compute(habit, occurrences, now: now);
    final first = DateTime(
        today.year, today.month, today.day - (HabitDetailScreen.historyDays - 1));
    final history = [
      for (final d in stats.days.reversed)
        if (!d.day.isBefore(first) && !d.day.isAfter(today)) d,
    ];
    return _HabitData(habit, stats, history);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  /// Run [action]; on error show a SnackBar and return false.
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

  Future<void> _onAction(
      AppLocalizations l, Habit habit, _HabitAction action) async {
    switch (action) {
      case _HabitAction.edit:
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
              builder: (_) => HabitFormScreen(habit: habit, now: widget.now)),
        );
        if (mounted) await _refresh();
        return;
      case _HabitAction.archive:
        if (!await showConfirmDialog(context,
            message: l.confirmArchiveHabit, confirmLabel: l.archive)) {
          return;
        }
        if (!await _guard(() => _repository.archiveHabit(habit.id))) return;
      case _HabitAction.delete:
        if (!await showConfirmDialog(context,
            message: l.confirmDeleteHabitPermanently,
            confirmLabel: l.habitDeletePermanently)) {
          return;
        }
        if (!await _guard(
            () => _repository.deleteHabitPermanently(habit.id))) {
          return;
        }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _editDay(
      AppLocalizations l, Habit habit, ResolvedHabitDay day) async {
    final today = HabitDay.of(_now());
    if (day.day.isAfter(today)) return;
    final result = await showModalBottomSheet<_DayEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DaySheet(habit: habit, day: day),
    );
    if (result == null || !mounted) return;
    if (day.day.isBefore(today) &&
        !await showConfirmDialog(context,
            message: l.habitConfirmEditPast
                .replaceAll('{date}', formatHabitDay(day.day)),
            confirmLabel: l.habitConfirmChange)) {
      return;
    }
    final ok = await _guard(() async {
      if (result.clear) {
        await _repository.clearOutcome(habit.id, day.day);
      } else {
        await _repository.recordOutcome(habit.id, day.day, result.outcome!,
            amount: result.amount, note: result.note);
      }
    });
    if (ok && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<_HabitData?>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.habits)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(l.habits)),
            body: Center(child: Text('${l.error}: ${snapshot.error}')),
          );
        }
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.habits)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.habitNotFound,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          );
        }
        final habit = data.habit;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              habit.title.isEmpty ? l.projectUntitled : habit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              PopupMenuButton<_HabitAction>(
                tooltip: l.habitMoreActions,
                onSelected: (a) => _onAction(l, habit, a),
                itemBuilder: (_) => [
                  PopupMenuItem(value: _HabitAction.edit, child: Text(l.edit)),
                  PopupMenuItem(
                      value: _HabitAction.archive, child: Text(l.archive)),
                  PopupMenuItem(
                      value: _HabitAction.delete,
                      child: Text(l.habitDeletePermanently)),
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
                _header(theme, l, habit),
                _sectionHeader(theme, l.habitStatistics),
                _statsSection(theme, l, data.stats),
                _sectionHeader(theme, l.habitRecentHistory),
                if (data.history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        Text(l.habitNoHistory, style: theme.textTheme.bodyMedium),
                  ),
                for (final d in data.history)
                  _dayTile(theme, l, habit, d, data.stats.today),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(ThemeData theme, AppLocalizations l, Habit habit) {
    final target = habitTargetLabel(l, habit.targetAmount, habit.unit);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: habit.color,
            child: const ExcludeSemantics(child: Icon(Icons.repeat)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.title.isEmpty ? l.projectUntitled : habit.title,
                    style: theme.textTheme.titleLarge),
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(habit.description, style: theme.textTheme.bodyMedium),
                ],
                if (target != null) ...[
                  const SizedBox(height: 4),
                  Text(target, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection(
      ThemeData theme, AppLocalizations l, HabitStatistics stats) {
    Widget metric(String label, String value) => Expanded(
          child: Semantics(
            label: '$label: $value',
            excludeSemantics: true,
            child: Column(
              children: [
                Text(value, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(label,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              metric(l.habitCurrentStreak, '${stats.currentStreak}'),
              metric(l.habitBestStreak, '${stats.bestStreak}'),
              metric(
                  l.habitCompletionRate, formatPercent(stats.completionRate)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in HabitOutcome.values)
                Semantics(
                  label: '${habitOutcomeLabel(l, o)}: ${stats.counts[o] ?? 0}',
                  excludeSemantics: true,
                  child: Chip(
                    avatar: Icon(habitOutcomeIcon(o),
                        size: 18,
                        color: habitOutcomeColor(theme.colorScheme, o)),
                    label: Text(
                        '${habitOutcomeLabel(l, o)}: ${stats.counts[o] ?? 0}'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayTile(ThemeData theme, AppLocalizations l, Habit habit,
      ResolvedHabitDay d, DateTime today) {
    final occ = d.isRecorded ? d.occurrence : null;
    final parts = <String>[
      habitOutcomeLabel(l, d.outcome),
      if (!d.isRecorded) l.habitNotRecorded,
      if (occ?.amount != null)
        '${formatHabitAmount(occ!.amount!)}'
            '${(habit.unit ?? '').isEmpty ? '' : ' ${habit.unit}'}',
      if ((occ?.note ?? '').isNotEmpty) occ!.note!,
    ];
    final dateText = d.day == today
        ? '${formatHabitDay(d.day)} · ${l.today}'
        : formatHabitDay(d.day);
    return ListTile(
      key: ValueKey('day-${HabitDay.format(d.day)}'),
      leading: HabitOutcomeIcon(outcome: d.outcome, isRecorded: d.isRecorded),
      title: Text(dateText),
      subtitle: Text(
        parts.join(' · '),
        style: d.isRecorded
            ? null
            : TextStyle(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: const ExcludeSemantics(child: Icon(Icons.edit_outlined)),
      onTap: () => _editDay(l, habit, d),
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
}

/// Bottom sheet to set a day's outcome (completed / partial / skipped /
/// missed), optional amount (habits with a target) and note, or clear it.
class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.habit, required this.day});

  final Habit habit;
  final ResolvedHabitDay day;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  static const _choices = [
    HabitOutcome.completed,
    HabitOutcome.partial,
    HabitOutcome.skipped,
    HabitOutcome.missed,
  ];

  late HabitOutcome? _outcome = widget.day.isRecorded &&
          _choices.contains(widget.day.occurrence?.outcome)
      ? widget.day.occurrence!.outcome
      : null;
  late final TextEditingController _amount = TextEditingController(
      text: widget.day.occurrence?.amount == null
          ? ''
          : formatHabitAmount(widget.day.occurrence!.amount!));
  late final TextEditingController _note =
      TextEditingController(text: widget.day.occurrence?.note ?? '');

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final outcome = _outcome;
    if (outcome == null) return;
    final amount = widget.habit.hasTarget
        ? double.tryParse(_amount.text.trim().replaceAll(',', '.'))
        : null;
    final note = _note.text.trim();
    Navigator.pop(
        context,
        _DayEdit.record(outcome,
            amount: amount, note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unit = (widget.habit.unit ?? '').trim();
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                    '${l.habitRecordDay} · ${formatHabitDay(widget.day.day)}',
                    style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in _choices)
                    ChoiceChip(
                      avatar: ExcludeSemantics(
                          child: Icon(habitOutcomeIcon(o), size: 18)),
                      label: Text(habitOutcomeLabel(l, o)),
                      selected: _outcome == o,
                      onSelected: (_) => setState(() => _outcome = o),
                    ),
                ],
              ),
              if (widget.habit.hasTarget) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  decoration: InputDecoration(
                    labelText: l.habitAmount,
                    suffixText: unit.isEmpty ? null : unit,
                    helperText: habitTargetLabel(
                        l, widget.habit.targetAmount, widget.habit.unit),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: l.habitNote),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.day.isRecorded)
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const _DayEdit.clear()),
                      child: Text(l.habitClearRecord),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _outcome == null ? null : _save,
                    child: Text(l.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
