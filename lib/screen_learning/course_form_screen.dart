import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_course.dart';
import '../domain/repositories/learning_repository.dart';
import 'learning_labels.dart';

/// Form tạo / sửa khóa học (Core Track C7). [course] == null → tạo mới (nguồn
/// luôn là [CourseSource.manual]); khác null → sửa (không đổi nguồn).
/// Trả về (Navigator.pop) `true` khi đã lưu.
class CourseFormScreen extends StatefulWidget {
  const CourseFormScreen({super.key, this.course});

  final Course? course;

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  late final LearningRepository _repository =
      context.read<LearningRepository>();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.course?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.course?.description ?? '');
  late CourseStatus _status = widget.course?.status ?? CourseStatus.active;
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
    final existing = widget.course;
    if (existing == null) {
      await _repository.createCourse(Course(
        title: title,
        description: description,
        source: CourseSource.manual,
      ));
    } else {
      await _repository.updateCourse(existing.copyWith(
        title: title,
        description: description,
        status: _status,
        updateTimeStamp: DateTime.now(),
      ));
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEdit = widget.course != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editCourse : l.newCourse),
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
            if (isEdit) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<CourseStatus>(
                initialValue: _status,
                decoration: InputDecoration(labelText: l.courseStatus),
                items: [
                  for (final s in CourseStatus.values)
                    DropdownMenuItem(
                        value: s, child: Text(courseStatusLabel(l, s))),
                ],
                onChanged: (s) {
                  if (s != null) setState(() => _status = s);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
