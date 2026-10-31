import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_habit_occurrence.dart';

/// Localized label of a habit outcome. Kept here so `app_localizations.dart`
/// does not depend on the domain model.
String habitOutcomeLabel(AppLocalizations l, HabitOutcome o) {
  switch (o) {
    case HabitOutcome.completed:
      return l.habitOutcomeCompleted;
    case HabitOutcome.partial:
      return l.habitOutcomePartial;
    case HabitOutcome.skipped:
      return l.habitOutcomeSkipped;
    case HabitOutcome.missed:
      return l.habitOutcomeMissed;
    case HabitOutcome.pending:
      return l.habitOutcomePending;
  }
}

/// Icon of a habit outcome.
IconData habitOutcomeIcon(HabitOutcome o) {
  switch (o) {
    case HabitOutcome.completed:
      return Icons.check_circle;
    case HabitOutcome.partial:
      return Icons.timelapse;
    case HabitOutcome.skipped:
      return Icons.skip_next;
    case HabitOutcome.missed:
      return Icons.cancel;
    case HabitOutcome.pending:
      return Icons.radio_button_unchecked;
  }
}

/// Color of a habit outcome icon (from the theme's color scheme).
Color habitOutcomeColor(ColorScheme cs, HabitOutcome o) {
  switch (o) {
    case HabitOutcome.completed:
      return Colors.green.shade700;
    case HabitOutcome.partial:
      return Colors.amber.shade800;
    case HabitOutcome.skipped:
      return cs.outline;
    case HabitOutcome.missed:
      return cs.error;
    case HabitOutcome.pending:
      return cs.onSurfaceVariant;
  }
}

/// `dd/MM/yyyy` (same as `DateField`).
String formatHabitDay(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

/// Amount without a trailing `.0` (e.g. 2 → "2", 2.5 → "2.5").
String formatHabitAmount(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// "Target: 10 pages" style label, or null without a target.
String? habitTargetLabel(AppLocalizations l, double? target, String? unit) {
  if (target == null) return null;
  final u = (unit ?? '').trim();
  final value = u.isEmpty
      ? formatHabitAmount(target)
      : '${formatHabitAmount(target)} $u';
  return l.habitTargetValue.replaceAll('{value}', value);
}

/// Outcome icon with a Semantics label (not decorative).
class HabitOutcomeIcon extends StatelessWidget {
  const HabitOutcomeIcon({
    super.key,
    required this.outcome,
    this.isRecorded = true,
    this.size = 24,
  });

  final HabitOutcome outcome;

  /// Derived (unrecorded) days are drawn outlined / faded and their label says
  /// "not recorded".
  final bool isRecorded;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final label = isRecorded
        ? habitOutcomeLabel(l, outcome)
        : '${habitOutcomeLabel(l, outcome)} (${l.habitNotRecorded})';
    final color = habitOutcomeColor(cs, outcome);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: isRecorded ? 1 : 0.55,
          child: Icon(habitOutcomeIcon(outcome), size: size, color: color),
        ),
      ),
    );
  }
}
