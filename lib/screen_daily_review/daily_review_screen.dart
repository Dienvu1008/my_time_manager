import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../application/daily_review/daily_review.dart';
import '../domain/models/model_calendar_event.dart';
import '../domain/repositories/calendar_repository.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/time_interval_repository.dart';
import '../screen_calendar/recurrence_expander.dart';
import '../screen_habits/habit_detail_screen.dart';
import '../shared/confirm_dialog.dart';

/// Builds the review [Availability] from the Daily Review settings (Phase
/// DR2). [workDayBits]: bit 0 = Monday … bit 6 = Sunday.
Availability availabilityFromSettings({
  required int workStartMinutes,
  required int workEndMinutes,
  required int workDayBits,
  required int bufferMinutes,
}) {
  final hours = WorkingHours(workStartMinutes, workEndMinutes);
  return Availability(
    workingHours: {
      for (var d = DateTime.monday; d <= DateTime.sunday; d++)
        if (workDayBits & (1 << (d - 1)) != 0) d: hours,
    },
    buffer: Duration(minutes: bufferMinutes),
  );
}

/// Expander shared with the Phase R reminder engine: recurring events block
/// availability through their expanded occurrences.
List<DateTime> _expand(CalendarEvent event, DateTime from, DateTime to) =>
    expandRecurringEvent(event, from, to)
        .map((o) => o.start.effective)
        .toList();

/// The user's choice for one reviewed interval.
class _Choice {
  _Choice(this.action);

  RescheduleAction action;
  int? durationMinutes;
  DateTime? targetDay;
  TimeOfDay? exactTime;
  int? firstMinutes;
  int? secondMinutes;
}

/// Daily Review (Phase DR2): unresolved work for today, per-item actions, a
/// deterministic proposal preview and a confirmed, validated apply.
///
/// Nothing is written until the user approves the confirmation dialog; the
/// apply re-validates every item against the current data (stale or
/// conflicting items are skipped and reported). Calendar events and habits
/// are never moved.
class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({
    super.key,
    this.availability = const Availability(),
    this.now,
  });

  final Availability availability;

  /// Injectable clock (tests). Defaults to [DateTime.now].
  final DateTime Function()? now;

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  late final TimeIntervalRepository _intervals =
      context.read<TimeIntervalRepository>();
  late final TaskRepository _tasks = context.read<TaskRepository>();
  late final CalendarRepository _calendar = context.read<CalendarRepository>();
  late final HabitRepository? _habits = context.read<HabitRepository?>();

  late final DailyReviewService _service = DailyReviewService(
    timeIntervals: _intervals,
    tasks: _tasks,
    calendar: _calendar,
    habits: _habits,
    expander: _expand,
  );
  late final ReschedulePlanner _planner = ReschedulePlanner(expander: _expand);
  late final ProposalApplier _applier = ProposalApplier(
    timeIntervals: _intervals,
    tasks: _tasks,
    calendar: _calendar,
    expander: _expand,
  );

  late Future<DailyReview> _future;
  final Map<String, _Choice> _choices = {};
  RescheduleProposal? _proposal;
  final Set<String> _accepted = {};
  ApplyResult? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _service.review(_now(), widget.availability);
  }

  Future<void> _reload({bool keepResult = false}) async {
    setState(() {
      _choices.clear();
      _proposal = null;
      _accepted.clear();
      if (!keepResult) _result = null;
      _future = _service.review(_now(), widget.availability);
    });
    await _future;
  }

  void _showError(Object e) {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
  }

  // ---------------------------------------------------------------------
  // Preview / apply
  // ---------------------------------------------------------------------

  List<ReviewSelection> _selections(DailyReview review) {
    final out = <ReviewSelection>[];
    for (final e in _choices.entries) {
      final c = e.value;
      final item = review.itemById(e.key);
      if (item == null) continue;
      Duration? minutes(int? m) =>
          m == null || m <= 0 ? null : Duration(minutes: m);
      DateTime? at;
      if (c.action == RescheduleAction.reschedule && c.exactTime != null) {
        final d = c.targetDay ?? review.day.add(const Duration(days: 1));
        at = DateTime(
            d.year, d.month, d.day, c.exactTime!.hour, c.exactTime!.minute);
      }
      out.add(ReviewSelection(
        e.key,
        c.action,
        duration: minutes(c.durationMinutes),
        targetDay: c.targetDay,
        at: at,
        firstPart: minutes(c.firstMinutes),
        secondPart: minutes(c.secondMinutes),
      ));
    }
    return out;
  }

  void _preview(DailyReview review) {
    try {
      final proposal = _planner.plan(
        review: review,
        selections: _selections(review),
        availability: widget.availability,
        now: _now(),
      );
      setState(() {
        _proposal = proposal;
        _result = null;
        _accepted
          ..clear()
          ..addAll(
              proposal.items.where((i) => i.isApplicable).map((i) => i.intervalId));
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> _confirm(ReviewConfirmationRequest req) async {
    final l = AppLocalizations.of(context)!;
    final lines = <String>[
      l.dailyReviewConfirmSummary
          .replaceAll('{moves}', '${req.moveCount}')
          .replaceAll('{creates}', '${req.createCount}')
          .replaceAll('{deletes}', '${req.deleteCount}'),
      if (req.deadlineMoveCount > 0)
        '${l.dailyReviewDeadlineWillMove}: ${req.deadlineMoveCount}',
      if (req.isDestructive) l.dailyReviewDeleteWarning,
    ];
    return showConfirmDialog(
      context,
      title: l.dailyReviewConfirmTitle,
      message: lines.join('\n'),
      confirmLabel: l.dailyReviewApply,
      destructive: req.isDestructive,
    );
  }

  Future<void> _apply() async {
    final proposal = _proposal;
    if (proposal == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await _applier.apply(proposal, Set.of(_accepted),
          confirm: _confirm, now: _now());
      if (!mounted) return;
      if (!result.confirmed) {
        setState(() => _busy = false);
        return; // declined: nothing changed, keep the preview
      }
      setState(() => _result = result);
      await _reload(keepResult: true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.dailyReview)),
      body: FutureBuilder<DailyReview>(
        future: _future,
        builder: (context, snapshot) {
          final review = snapshot.data;
          if (snapshot.hasError) {
            return Center(child: Text('${l.error}: ${snapshot.error}'));
          }
          if (review == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _summary(context, l, review),
                if (_result != null) ..._resultSection(context, l, _result!),
                if (review.isAllClear)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      const ExcludeSemantics(
                          child: Icon(Icons.celebration_outlined, size: 48)),
                      const SizedBox(height: 12),
                      Text(l.dailyReviewEmpty,
                          key: const ValueKey('dr-empty'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium),
                    ]),
                  ),
                ..._itemSection(
                    context, l, l.dailyReviewSectionOverdue, review.overdue),
                ..._itemSection(context, l, l.dailyReviewSectionStarted,
                    review.startedIncomplete),
                ..._itemSection(
                    context, l, l.dailyReviewSectionDueToday, review.dueToday),
                ..._habitSection(context, l, review),
                if (review.unscheduledTasks.isNotEmpty)
                  ExpansionTile(
                    title: Text(
                        '${l.dailyReviewSectionUnscheduled} (${review.unscheduledTasks.length})'),
                    children: [
                      for (final t in review.unscheduledTasks)
                        ListTile(dense: true, title: Text(t.title)),
                    ],
                  ),
                if (_proposal != null) ..._proposalSection(context, l, review),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<DailyReview>(
        future: _future,
        builder: (context, snapshot) {
          final review = snapshot.data;
          if (review == null || review.items.isEmpty) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('dr-preview'),
                    onPressed: _choices.isEmpty || _busy
                        ? null
                        : () => _preview(review),
                    icon: const Icon(Icons.preview_outlined),
                    label: Text(l.dailyReviewPreview),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('dr-apply'),
                    onPressed: _proposal == null || _accepted.isEmpty || _busy
                        ? null
                        : _apply,
                    icon: const Icon(Icons.check),
                    label: Text(l.dailyReviewApply),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _summary(BuildContext context, AppLocalizations l, DailyReview r) {
    String dur(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
    }

    Widget metric(String label, String value) => Expanded(
          child: Semantics(
            label: '$label: $value',
            excludeSemantics: true,
            child: Column(children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        );
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            metric(l.dailyReviewSectionOverdue, '${r.overdueCount}'),
            metric(l.dailyReviewSectionStarted, '${r.startedCount}'),
            metric(l.dailyReviewSectionDueToday, '${r.dueTodayCount}'),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            metric(l.dailyReviewFreeTime, dur(r.freeTimeToday)),
            metric(l.dailyReviewWorkload, dur(r.knownWorkload)),
            metric(l.dailyReviewSectionHabits, '${r.habitsOpenCount}'),
          ]),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Semantics(
          header: true,
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      );

  String _range(BuildContext context, DateTime? s, DateTime? e) {
    final ml = MaterialLocalizations.of(context);
    String f(DateTime d) =>
        '${ml.formatShortMonthDay(d)} ${TimeOfDay.fromDateTime(d).format(context)}';
    if (s == null && e == null) return AppLocalizations.of(context)!.dailyReviewNoTime;
    if (s != null && e != null) return '${f(s)} – ${f(e)}';
    return f((s ?? e)!);
  }

  String _actionLabel(AppLocalizations l, RescheduleAction a) => switch (a) {
        RescheduleAction.doNow => l.dailyReviewActionDoNow,
        RescheduleAction.reschedule => l.dailyReviewActionReschedule,
        RescheduleAction.split => l.dailyReviewActionSplit,
        RescheduleAction.keepPending => l.dailyReviewActionKeepPending,
        RescheduleAction.cancelOccurrence => l.dailyReviewActionCancel,
      };

  List<Widget> _itemSection(BuildContext context, AppLocalizations l,
      String title, List<ReviewItem> items) {
    if (items.isEmpty) return const [];
    return [
      _header(context, '$title (${items.length})'),
      for (final item in items) _itemTile(context, l, item),
    ];
  }

  Widget _itemTile(BuildContext context, AppLocalizations l, ReviewItem item) {
    final choice = _choices[item.id];
    final name = item.interval.title.isNotEmpty
        ? item.interval.title
        : (item.task?.title ?? '');
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('dr-item-${item.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              if (item.isImportant)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const ExcludeSemantics(
                        child: Icon(Icons.priority_high, size: 16)),
                    label: Text(l.dailyReviewImportantBadge),
                  ),
                ),
              if (item.isDeadline)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.errorContainer,
                    avatar: const ExcludeSemantics(
                        child: Icon(Icons.flag_outlined, size: 16)),
                    label: Text(l.dailyReviewDeadlineBadge),
                  ),
                ),
            ]),
            if (item.task != null && item.task!.title != name)
              Text(item.task!.title,
                  style: Theme.of(context).textTheme.bodySmall),
            Text(_range(context, item.start, item.end),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            DropdownButton<RescheduleAction?>(
              key: ValueKey('dr-action-${item.id}'),
              isExpanded: true,
              value: choice?.action,
              hint: Text(l.dailyReviewNoAction),
              items: [
                DropdownMenuItem<RescheduleAction?>(
                    value: null, child: Text(l.dailyReviewNoAction)),
                for (final a in RescheduleAction.values)
                  DropdownMenuItem<RescheduleAction?>(
                      value: a, child: Text(_actionLabel(l, a))),
              ],
              onChanged: _busy
                  ? null
                  : (a) => setState(() {
                        _proposal = null;
                        _accepted.clear();
                        if (a == null) {
                          _choices.remove(item.id);
                        } else {
                          (_choices[item.id] ??= _Choice(a)).action = a;
                        }
                      }),
            ),
            if (choice != null) ..._choiceFields(context, l, item, choice),
          ],
        ),
      ),
    );
  }

  List<Widget> _choiceFields(
      BuildContext context, AppLocalizations l, ReviewItem item, _Choice c) {
    void changed(VoidCallback f) => setState(() {
          f();
          _proposal = null;
          _accepted.clear();
        });
    Widget minutesField(String key, String label, int? value,
            ValueChanged<int?> onChanged) =>
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextFormField(
            key: ValueKey(key),
            initialValue: value?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: label, isDense: true),
            onChanged: (v) => changed(() => onChanged(int.tryParse(v.trim()))),
          ),
        );

    final needsDuration = item.duration == null &&
        (c.action == RescheduleAction.doNow ||
            c.action == RescheduleAction.reschedule ||
            c.action == RescheduleAction.split);
    final ml = MaterialLocalizations.of(context);
    return [
      if (needsDuration)
        minutesField('dr-duration-${item.id}', l.dailyReviewDurationHint,
            c.durationMinutes, (v) => c.durationMinutes = v),
      if (c.action == RescheduleAction.reschedule ||
          c.action == RescheduleAction.split)
        Wrap(spacing: 8, children: [
          TextButton.icon(
            icon: const Icon(Icons.event_outlined),
            label: Text(c.targetDay == null
                ? l.dailyReviewTargetDay
                : '${l.dailyReviewTargetDay}: ${ml.formatShortMonthDay(c.targetDay!)}'),
            onPressed: () async {
              final today = DateTime(_now().year, _now().month, _now().day);
              final picked = await showDatePicker(
                context: context,
                initialDate: c.targetDay ?? today.add(const Duration(days: 1)),
                firstDate: today,
                lastDate: today.add(const Duration(days: 365)),
              );
              if (picked != null) changed(() => c.targetDay = picked);
            },
          ),
          if (c.action == RescheduleAction.reschedule)
            TextButton.icon(
              icon: const Icon(Icons.schedule),
              label: Text(c.exactTime == null
                  ? l.dailyReviewExactTime
                  : c.exactTime!.format(context)),
              onPressed: () async {
                final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        c.exactTime ?? const TimeOfDay(hour: 9, minute: 0));
                if (picked != null) changed(() => c.exactTime = picked);
              },
            ),
        ]),
      if (c.action == RescheduleAction.split) ...[
        minutesField('dr-first-${item.id}', l.dailyReviewFirstPart,
            c.firstMinutes, (v) => c.firstMinutes = v),
        minutesField('dr-second-${item.id}', l.dailyReviewSecondPart,
            c.secondMinutes, (v) => c.secondMinutes = v),
      ],
      if (c.action == RescheduleAction.cancelOccurrence)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l.dailyReviewDeleteWarning,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
    ];
  }

  List<Widget> _habitSection(
      BuildContext context, AppLocalizations l, DailyReview r) {
    final entries = [...r.habitsPending, ...r.habitsMissed];
    if (entries.isEmpty) return const [];
    return [
      _header(context, '${l.dailyReviewSectionHabits} (${entries.length})'),
      for (final e in entries)
        ListTile(
          leading: const ExcludeSemantics(child: Icon(Icons.repeat)),
          title: Text(e.habit.title),
          subtitle: Text(e.outcome.name),
          trailing: IconButton(
            tooltip: l.dailyReviewHabitOpenDetail,
            icon: const Icon(Icons.chevron_right),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) =>
                      HabitDetailScreen(habitId: e.habit.id, now: widget.now)));
              if (mounted) await _reload();
            },
          ),
        ),
    ];
  }

  String _statusLabel(AppLocalizations l, ProposalItem i) {
    switch (i.status) {
      case ProposalItemStatus.ready:
        return i.isApplicable ? '' : l.dailyReviewStatusConflict;
      case ProposalItemStatus.noChange:
        return l.dailyReviewStatusNoChange;
      case ProposalItemStatus.needsDuration:
        return l.dailyReviewStatusNeedsDuration;
      case ProposalItemStatus.noCapacity:
        return l.dailyReviewStatusNoCapacity;
      case ProposalItemStatus.unresolvable:
        return l.dailyReviewStatusUnresolvable;
      case ProposalItemStatus.conflict:
        return l.dailyReviewStatusConflict;
    }
  }

  List<Widget> _proposalSection(
      BuildContext context, AppLocalizations l, DailyReview review) {
    final p = _proposal!;
    return [
      _header(context, l.dailyReviewPreview),
      if (p.items.every((i) => !i.isApplicable))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l.dailyReviewNothingToApply),
        ),
      for (final i in p.items)
        CheckboxListTile(
          key: ValueKey('dr-proposal-${i.intervalId}'),
          value: _accepted.contains(i.intervalId),
          onChanged: !i.isApplicable || _busy
              ? null
              : (v) => setState(() => v == true
                  ? _accepted.add(i.intervalId)
                  : _accepted.remove(i.intervalId)),
          title: Text(review.itemById(i.intervalId)?.interval.title ??
              i.intervalId),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_actionLabel(l, i.action)),
              for (final c in i.changes)
                Text(c.proposed == null
                    ? '${_range(context, c.current?.start, c.current?.end)} → ✕'
                    : '${c.current == null ? '+' : _range(context, c.current!.start, c.current!.end)}'
                        ' → ${_range(context, c.proposed!.start, c.proposed!.end)}'),
              if (_statusLabel(l, i).isNotEmpty)
                Text(_statusLabel(l, i),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (i.movesDeadline)
                Text(l.dailyReviewDeadlineWillMove,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (i.isDestructive) Text(l.dailyReviewDeleteWarning),
            ],
          ),
        ),
    ];
  }

  List<Widget> _resultSection(
      BuildContext context, AppLocalizations l, ApplyResult r) {
    String label(ApplyOutcome o) => switch (o) {
          ApplyOutcome.applied => l.dailyReviewStatusApplied,
          ApplyOutcome.noChange => l.dailyReviewStatusNoChange,
          ApplyOutcome.notApplicable => l.dailyReviewStatusNotApplicable,
          ApplyOutcome.notConfirmed => l.dailyReviewStatusNotApplicable,
          ApplyOutcome.rejectedStale => l.dailyReviewStatusStale,
          ApplyOutcome.rejectedConflict => l.dailyReviewStatusConflict,
          ApplyOutcome.failed => l.dailyReviewStatusFailed,
        };
    return [
      _header(context, l.dailyReviewResults),
      if (r.isPartial)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l.dailyReviewPartialResult,
              key: const ValueKey('dr-partial'),
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      for (final i in r.results)
        ListTile(
          dense: true,
          key: ValueKey('dr-result-${i.intervalId}'),
          leading: Icon(
            i.outcome == ApplyOutcome.applied
                ? Icons.check_circle_outline
                : Icons.info_outline,
            semanticLabel: label(i.outcome),
          ),
          title: Text(label(i.outcome)),
          subtitle: Text(i.intervalId),
        ),
    ];
  }
}
