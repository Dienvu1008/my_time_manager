import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_habit.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/services/repeat_rule.dart';
import '../screen_tasks/component_widgets/listtile_repeat.dart';
import '../shared/color_choice_field.dart';
import '../shared/date_field.dart';

/// Create / edit form of a habit (Phase H2). [habit] == null → create.
/// Pops `true` once saved.
///
/// The recurrence is edited with the existing [RepeatListTile] (the same
/// editor used for repeating time intervals), pre-filled with the habit's rule
/// and without the "no repeat" preset. The reminder time is only stored here;
/// scheduling it is Phase H3.
class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habit, this.now});

  final Habit? habit;

  /// Injectable clock (default start date = today). Defaults to
  /// [DateTime.now].
  final DateTime Function()? now;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  late final HabitRepository _repository = context.read<HabitRepository>();
  final _formKey = GlobalKey<FormState>();
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  late final Habit? _existing = widget.habit;
  late final TextEditingController _title =
      TextEditingController(text: _existing?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: _existing?.description ?? '');
  late final TextEditingController _target = TextEditingController(
      text: _existing?.targetAmount == null
          ? ''
          : _formatNumber(_existing!.targetAmount!));
  late final TextEditingController _unit =
      TextEditingController(text: _existing?.unit ?? '');
  late Color _color = _existing?.color ?? Colors.white;
  late RepeatRule _recurrence =
      _existing?.recurrence ?? Habit.defaultRecurrence;
  late bool _partialCounts = _existing?.partialCountsTowardStreak ?? false;
  late DateTime _startDate = _existing?.startDate ?? HabitDay.of(_now());
  late DateTime? _endDate = _existing?.endDate;
  late TimeOfDay? _reminder = _parseTime(_existing?.reminderTime);
  String? _endDateError;
  bool _saving = false;

  static String _formatNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static TimeOfDay? _parseTime(String? raw) {
    final norm = HabitDay.normalizeTime(raw);
    if (norm == null) return null;
    final parts = norm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  double? _parseTarget() {
    final raw = _target.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  bool _validateDates(AppLocalizations l) {
    final end = _endDate;
    final error = end != null && HabitDay.of(end).isBefore(_startDate)
        ? l.habitEndBeforeStart
        : null;
    setState(() => _endDateError = error);
    return error == null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context)!;
    final formOk = _formKey.currentState?.validate() ?? false;
    final datesOk = _validateDates(l);
    if (!formOk || !datesOk) return;
    setState(() => _saving = true);
    final target = _parseTarget();
    final unit = _unit.text.trim();
    final existing = _existing;
    final habit = Habit(
      id: existing?.id,
      title: _title.text.trim(),
      description: _description.text.trim(),
      color: _color,
      recurrence: _recurrence,
      targetAmount: target,
      unit: target == null || unit.isEmpty ? null : unit,
      partialCountsTowardStreak: _partialCounts,
      startDate: _startDate,
      endDate: _endDate,
      reminderTime: _reminder == null ? null : _formatTime(_reminder!),
      isArchived: existing?.isArchived ?? false,
      archivedAt: existing?.archivedAt,
      createdAt: existing?.createdAt,
      updateTimeStamp: DateTime.now(),
      deviceId: existing?.deviceId,
    );
    var saved = false;
    try {
      if (existing == null) {
        await _repository.createHabit(habit);
      } else {
        await _repository.updateHabit(habit);
      }
      saved = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
    } finally {
      if (mounted && !saved) setState(() => _saving = false);
    }
    if (!saved || !mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && mounted) setState(() => _reminder = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEdit = _existing != null;
    final reminder = _reminder;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editHabit : l.newHabit),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l.save,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              autofocus: !isEdit,
              decoration: InputDecoration(labelText: l.title),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.titleRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: l.description),
              minLines: 2,
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            ColorChoiceField(
              value: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 8),
            // Reused recurrence editor (see class doc).
            RepeatListTile(
              initialRule: _recurrence,
              showNone: false,
              onChanged: (rule) => _recurrence = rule,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _target,
                    decoration:
                        InputDecoration(labelText: l.habitTargetAmount),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) {
                      final raw = (v ?? '').trim();
                      if (raw.isEmpty) return null;
                      final parsed = double.tryParse(raw.replaceAll(',', '.'));
                      return parsed == null || parsed <= 0
                          ? l.habitTargetInvalid
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unit,
                    decoration: InputDecoration(labelText: l.unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.habitPartialCounts),
              value: _partialCounts,
              onChanged: (v) => setState(() => _partialCounts = v),
            ),
            const SizedBox(height: 8),
            DateField(
              label: l.startDate,
              value: _startDate,
              clearable: false,
              onChanged: (d) {
                if (d == null) return;
                setState(() => _startDate = HabitDay.of(d));
                if (_endDateError != null) _validateDates(l);
              },
            ),
            const SizedBox(height: 16),
            DateField(
              label: l.endDate,
              value: _endDate,
              errorText: _endDateError,
              onChanged: (d) {
                setState(() => _endDate = d == null ? null : HabitDay.of(d));
                if (_endDateError != null) _validateDates(l);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickReminder,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l.habitReminderTime,
                  suffixIcon: reminder == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l.habitClearReminderTime,
                          onPressed: () => setState(() => _reminder = null),
                        ),
                ),
                child: Text(
                    reminder == null ? l.dateNotSet : _formatTime(reminder)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
