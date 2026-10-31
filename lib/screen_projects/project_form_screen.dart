import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_project.dart';
import '../domain/repositories/project_repository.dart';
import '../shared/color_choice_field.dart';
import '../shared/date_field.dart';
import 'project_labels.dart';

/// Form tạo / sửa dự án. [project] == null → tạo mới; khác null → sửa.
/// Trả về (Navigator.pop) `true` khi đã lưu.
class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.project});

  final Project? project;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  late final ProjectRepository _repository = context.read<ProjectRepository>();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.project?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.project?.description ?? '');
  late Color _color = widget.project?.color ?? Colors.white;
  late ProjectStatus _status = widget.project?.status ?? ProjectStatus.active;
  late DateTime? _startDate = widget.project?.startDate;
  late DateTime? _targetDate = widget.project?.targetDate;
  bool _dateError = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    final start = _startDate;
    final target = _targetDate;
    final dateError =
        start != null && target != null && target.isBefore(start);
    setState(() => _dateError = dateError);
    if (!valid || dateError) return;
    setState(() => _saving = true);
    final title = _title.text.trim();
    final description = _description.text.trim();
    final existing = widget.project;
    var saved = false;
    try {
      if (existing == null) {
        await _repository.createProject(Project(
          title: title,
          description: description,
          color: _color,
          status: _status,
          startDate: start,
          targetDate: target,
        ));
      } else {
        await _repository.updateProject(existing.copyWith(
          title: title,
          description: description,
          color: _color,
          status: _status,
          startDate: start,
          clearStartDate: start == null,
          targetDate: target,
          clearTargetDate: target == null,
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
    final theme = Theme.of(context);
    final isEdit = widget.project != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editProject : l.newProject),
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
            DropdownButtonFormField<ProjectStatus>(
              initialValue: _status,
              decoration: InputDecoration(labelText: l.projectStatus),
              items: [
                for (final s in ProjectStatus.values)
                  DropdownMenuItem(
                      value: s, child: Text(projectStatusLabel(l, s))),
              ],
              onChanged: (s) {
                if (s != null) setState(() => _status = s);
              },
            ),
            const SizedBox(height: 16),
            DateField(
              label: l.projectStartDate,
              value: _startDate,
              onChanged: (d) => setState(() => _startDate = d),
            ),
            const SizedBox(height: 16),
            DateField(
              label: l.projectTargetDate,
              value: _targetDate,
              onChanged: (d) => setState(() => _targetDate = d),
            ),
            if (_dateError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  l.projectTargetBeforeStart,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
