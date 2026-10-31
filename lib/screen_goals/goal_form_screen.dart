import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_goal.dart';
import '../domain/repositories/goal_repository.dart';
import '../shared/color_choice_field.dart';
import '../shared/date_field.dart';
import 'goal_labels.dart';

/// Form tạo / sửa mục tiêu. [goal] == null → tạo mới; khác null → sửa.
/// Trả về (Navigator.pop) `true` khi đã lưu.
class GoalFormScreen extends StatefulWidget {
  const GoalFormScreen({super.key, this.goal});

  final Goal? goal;

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  late final GoalRepository _repository = context.read<GoalRepository>();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.goal?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.goal?.description ?? '');
  late Color _color = widget.goal?.color ?? Colors.white;
  late GoalStatus _status = widget.goal?.status ?? GoalStatus.active;
  late DateTime? _targetDate = widget.goal?.targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final title = _title.text.trim();
    final description = _description.text.trim();
    final existing = widget.goal;
    var saved = false;
    try {
      if (existing == null) {
        await _repository.createGoal(Goal(
          title: title,
          description: description,
          color: _color,
          status: _status,
          targetDate: _targetDate,
        ));
      } else {
        await _repository.updateGoal(existing.copyWith(
          title: title,
          description: description,
          color: _color,
          status: _status,
          targetDate: _targetDate,
          clearTargetDate: _targetDate == null,
          updateTimeStamp: DateTime.now(),
        ));
      }
      saved = true;
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
    } finally {
      if (mounted && !saved) setState(() => _saving = false);
    }
    if (!saved || !mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEdit = widget.goal != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editGoal : l.newGoal),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<GoalStatus>(
              initialValue: _status,
              decoration: InputDecoration(labelText: l.goalStatus),
              items: [
                for (final s in GoalStatus.values)
                  DropdownMenuItem(value: s, child: Text(goalStatusLabel(l, s))),
              ],
              onChanged: (s) {
                if (s != null) setState(() => _status = s);
              },
            ),
            const SizedBox(height: 16),
            DateField(
              label: l.goalTargetDate,
              value: _targetDate,
              onChanged: (d) => setState(() => _targetDate = d),
            ),
          ],
        ),
      ),
    );
  }
}
