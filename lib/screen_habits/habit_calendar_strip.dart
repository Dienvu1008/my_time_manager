import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_habit.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/services/habit_calendar_projection.dart';
import 'habit_detail_screen.dart';
import 'habit_labels.dart';

/// Read-only habit markers for the calendar (Phase H3): one chip per
/// [HabitCalendarEntry] of the local days `[from, to]`, shown in the
/// calendar's top (all-day) area — visually distinct from events / intervals
/// (habit icon in the habit's color + outcome icon). Timed habits show their
/// reminder time in the label and are ordered by it.
///
/// Tapping a chip opens [HabitDetailScreen] (the habit check-in workflow,
/// where a day's outcome is recorded via `HabitRepository`); calendar data is
/// never edited. Renders nothing when there is no [HabitRepository] in scope
/// or no entry in the range, so existing calendar rendering is unchanged.
class HabitCalendarStrip extends StatefulWidget {
  const HabitCalendarStrip({
    super.key,
    required this.from,
    required this.to,
    this.showDate = false,
    this.now,
  });

  /// First / last local day (inclusive).
  final DateTime from;
  final DateTime to;

  /// Prefix each chip with its weekday + day (multi-day ranges, e.g. week).
  final bool showDate;

  /// Injectable clock (tests). Defaults to [DateTime.now].
  final DateTime Function()? now;

  @override
  State<HabitCalendarStrip> createState() => _HabitCalendarStripState();
}

class _HabitCalendarStripState extends State<HabitCalendarStrip> {
  static const _projection = HabitCalendarProjection();

  HabitRepository? _repository;
  Future<List<HabitCalendarEntry>>? _future;

  DateTime Function() get _now => widget.now ?? DateTime.now;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<HabitRepository?>();
    if (repo != _repository) {
      _repository = repo;
      _reload();
    }
  }

  @override
  void didUpdateWidget(HabitCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (HabitDay.of(oldWidget.from) != HabitDay.of(widget.from) ||
        HabitDay.of(oldWidget.to) != HabitDay.of(widget.to)) {
      _reload();
    }
  }

  void _reload() {
    final repo = _repository;
    _future = repo == null
        ? null
        : _projection.load(repo,
            from: HabitDay.of(widget.from),
            to: HabitDay.of(widget.to),
            now: _now());
  }

  Future<void> _open(HabitCalendarEntry e) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(habitId: e.habitId, now: widget.now),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<HabitCalendarEntry>>(
      future: future,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <HabitCalendarEntry>[];
        if (entries.isEmpty) return const SizedBox.shrink();
        final l = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        return Semantics(
          container: true,
          label: l.habits,
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  for (final e in entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _chip(context, l, e),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context, AppLocalizations l, HabitCalendarEntry e) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = e.title.isEmpty ? l.projectUntitled : e.title;
    final parts = <String>[
      if (widget.showDate) DateFormat.MEd(locale).format(e.localDate),
      if (e.reminderTime != null) e.reminderTime!,
      title,
    ];
    final label = parts.join(' · ');
    final outcome = e.isRecorded
        ? habitOutcomeLabel(l, e.outcome)
        : '${habitOutcomeLabel(l, e.outcome)} (${l.habitNotRecorded})';
    return Tooltip(
      message: l.habitOpenCheckIn,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: '${l.habits}: $label, $outcome',
        hint: l.habitOpenCheckIn,
        excludeSemantics: true,
        child: ActionChip(
          key: ValueKey(
              'habit-calendar-${e.habitId}-${HabitDay.format(e.localDate)}'),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          side: BorderSide(color: e.color, width: 1.5),
          avatar: HabitOutcomeIcon(
              outcome: e.outcome, isRecorded: e.isRecorded, size: 18),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: e.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.repeat, size: 14),
              const SizedBox(width: 4),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          onPressed: () => _open(e),
        ),
      ),
    );
  }
}
