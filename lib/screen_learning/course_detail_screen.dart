import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_course.dart';
import '../domain/models/model_course_module.dart';
import '../domain/models/model_lesson.dart';
import '../domain/models/model_lesson_progress.dart';
import '../domain/repositories/learning_repository.dart';
import '../domain/services/learning_progress_service.dart';
import 'course_form_screen.dart';
import 'learning_labels.dart';
import 'lesson_screen.dart';

/// Màn chi tiết một khóa học (Core Track C7): mô tả, trạng thái, tiến độ suy
/// ra, danh sách chương với bài học. Thêm / sửa / sắp xếp (lên/xuống) / xóa
/// chương và bài; sửa / lưu trữ / chuyển vào thùng rác khóa học.
///
/// Chương và bài bị xóa CỨNG (không có thùng rác riêng) sau hộp thoại xác nhận;
/// khóa học dùng soft-delete / archive rồi đóng màn với kết quả `true`.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseData {
  const _CourseData({
    required this.course,
    required this.modules,
    required this.lessonsByModule,
    required this.statusById,
    required this.progress,
  });

  final Course course;
  final List<CourseModule> modules;
  final Map<String, List<Lesson>> lessonsByModule;
  final Map<String, LessonStatus> statusById;
  final CourseProgress? progress;
}

enum _ItemAction { edit, moveUp, moveDown, delete }

enum _CourseAction { archive, trash }

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final LearningRepository _repository =
      context.read<LearningRepository>();
  late final LearningProgressService _progress =
      context.read<LearningProgressService>();
  late Future<_CourseData?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_CourseData?> _load() async {
    final course = await _repository.getCourse(widget.courseId);
    if (course == null) return null;
    final modules = await _repository.getModules(course.id);
    final lessons = await _repository.getLessonsOfCourse(course.id);
    final rows = await _repository.getProgressForCourse(course.id);
    final byModule = <String, List<Lesson>>{
      for (final m in modules) m.id: <Lesson>[],
    };
    for (final l in lessons) {
      byModule[l.moduleId]?.add(l);
    }
    return _CourseData(
      course: course,
      modules: modules,
      lessonsByModule: byModule,
      statusById: LearningProgressService.statusById(rows),
      progress: await _progress.courseProgressOf(course.id),
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  // ---------------- Course actions ----------------

  Future<void> _editCourse(Course course) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CourseFormScreen(course: course)),
    );
    if (mounted) await _refresh();
  }

  Future<void> _onCourseAction(_CourseAction action) async {
    switch (action) {
      case _CourseAction.archive:
        await _repository.archiveCourse(widget.courseId);
      case _CourseAction.trash:
        await _repository.softDeleteCourse(widget.courseId);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // ---------------- Module actions ----------------

  /// Hộp thoại tiêu đề + mô tả chương; trả về (title, description) hoặc null.
  Future<(String, String)?> _showModuleDialog(
      AppLocalizations l, CourseModule? module) {
    return showDialog<(String, String)>(
      context: context,
      builder: (_) => _TextFieldsDialog(
        title: module == null ? l.newModule : l.editModule,
        confirmLabel: l.save,
        initialTitle: module?.title ?? '',
        initialDescription: module?.description ?? '',
        withDescription: true,
      ),
    );
  }

  Future<void> _addModule(AppLocalizations l, _CourseData data) async {
    final result = await _showModuleDialog(l, null);
    if (result == null) return;
    await _repository.createModule(CourseModule(
      courseId: data.course.id,
      title: result.$1,
      description: result.$2,
      sortOrder: data.modules.length,
    ));
    if (mounted) await _refresh();
  }

  Future<bool> _confirm(AppLocalizations l, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _onModuleAction(AppLocalizations l, _CourseData data,
      CourseModule module, _ItemAction action) async {
    switch (action) {
      case _ItemAction.edit:
        final result = await _showModuleDialog(l, module);
        if (result == null) return;
        await _repository.updateModule(module.copyWith(
          title: result.$1,
          description: result.$2,
          updateTimeStamp: DateTime.now(),
        ));
      case _ItemAction.moveUp:
      case _ItemAction.moveDown:
        final ids = [for (final m in data.modules) m.id];
        if (!_swap(ids, module.id, action == _ItemAction.moveUp)) return;
        await _repository.reorderModules(data.course.id, ids);
      case _ItemAction.delete:
        if (!await _confirm(l, l.confirmDeleteModule)) return;
        await _repository.deleteModule(module.id);
    }
    if (mounted) await _refresh();
  }

  // ---------------- Lesson actions ----------------

  /// Hộp thoại tiêu đề bài học mới; trả về tiêu đề hoặc null.
  Future<String?> _showLessonDialog(AppLocalizations l) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _TextFieldsDialog(
        title: l.newLesson,
        confirmLabel: l.add,
      ),
    );
    return result?.$1;
  }

  Future<void> _addLesson(
      AppLocalizations l, _CourseData data, CourseModule module) async {
    final title = await _showLessonDialog(l);
    if (title == null) return;
    final lesson = Lesson(
      moduleId: module.id,
      title: title,
      sortOrder: data.lessonsByModule[module.id]?.length ?? 0,
    );
    await _repository.createLesson(lesson);
    if (!mounted) return;
    await _openLesson(lesson.id);
  }

  Future<void> _openLesson(String lessonId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => LessonScreen(lessonId: lessonId)),
    );
    if (mounted) await _refresh();
  }

  Future<void> _onLessonAction(AppLocalizations l, _CourseData data,
      CourseModule module, Lesson lesson, _ItemAction action) async {
    switch (action) {
      case _ItemAction.edit:
        await _openLesson(lesson.id);
        return;
      case _ItemAction.moveUp:
      case _ItemAction.moveDown:
        final ids = [
          for (final x in data.lessonsByModule[module.id] ?? const <Lesson>[])
            x.id,
        ];
        if (!_swap(ids, lesson.id, action == _ItemAction.moveUp)) return;
        await _repository.reorderLessons(module.id, ids);
      case _ItemAction.delete:
        if (!await _confirm(l, l.confirmDeleteLesson)) return;
        await _repository.deleteLesson(lesson.id);
    }
    if (mounted) await _refresh();
  }

  /// Đổi chỗ [id] với phần tử liền trước / liền sau. false nếu không đổi được.
  static bool _swap(List<String> ids, String id, bool up) {
    final i = ids.indexOf(id);
    final j = up ? i - 1 : i + 1;
    if (i < 0 || j < 0 || j >= ids.length) return false;
    final tmp = ids[i];
    ids[i] = ids[j];
    ids[j] = tmp;
    return true;
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<_CourseData?>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.courses)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(l.courses)),
            body: Center(child: Text('${l.error}: ${snapshot.error}')),
          );
        }
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.courses)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.courseNotFound,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          );
        }
        final course = data.course;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              course.title.isEmpty ? l.learningUntitled : course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.editCourse,
                onPressed: () => _editCourse(course),
              ),
              PopupMenuButton<_CourseAction>(
                onSelected: _onCourseAction,
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: _CourseAction.archive, child: Text(l.archive)),
                  PopupMenuItem(
                      value: _CourseAction.trash, child: Text(l.moveToTrash)),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            tooltip: l.addModule,
            onPressed: () => _addModule(l, data),
            icon: const Icon(Icons.add),
            label: Text(l.addModule),
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _Header(course: course, progress: data.progress, l: l),
                if (data.modules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.noModulesYet,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                for (var i = 0; i < data.modules.length; i++)
                  _moduleCard(context, l, data, i),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _moduleCard(
      BuildContext context, AppLocalizations l, _CourseData data, int index) {
    final theme = Theme.of(context);
    final module = data.modules[index];
    final lessons = data.lessonsByModule[module.id] ?? const <Lesson>[];
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      module.title.isEmpty ? l.learningUntitled : module.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                PopupMenuButton<_ItemAction>(
                  onSelected: (a) => _onModuleAction(l, data, module, a),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: _ItemAction.edit, child: Text(l.editModule)),
                    if (index > 0)
                      PopupMenuItem(
                          value: _ItemAction.moveUp, child: Text(l.moveUp)),
                    if (index < data.modules.length - 1)
                      PopupMenuItem(
                          value: _ItemAction.moveDown,
                          child: Text(l.moveDown)),
                    PopupMenuItem(
                        value: _ItemAction.delete, child: Text(l.delete)),
                  ],
                ),
              ],
            ),
          ),
          if (module.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(module.description, style: theme.textTheme.bodySmall),
            ),
          if (lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(l.noLessonsYet, style: theme.textTheme.bodyMedium),
            ),
          for (var j = 0; j < lessons.length; j++)
            _lessonTile(l, data, module, lessons, j),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: TextButton.icon(
              onPressed: () => _addLesson(l, data, module),
              icon: const Icon(Icons.add),
              label: Text(l.addLesson),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonTile(AppLocalizations l, _CourseData data, CourseModule module,
      List<Lesson> lessons, int index) {
    final lesson = lessons[index];
    final status = data.statusById[lesson.id] ?? LessonStatus.notStarted;
    final icon = switch (status) {
      LessonStatus.completed => Icons.check_circle,
      LessonStatus.inProgress => Icons.timelapse,
      LessonStatus.notStarted => Icons.radio_button_unchecked,
    };
    return ListTile(
      leading: Icon(icon, semanticLabel: lessonStatusLabel(l, status)),
      title: Text(lesson.title.isEmpty ? l.learningUntitled : lesson.title),
      onTap: () => _openLesson(lesson.id),
      trailing: PopupMenuButton<_ItemAction>(
        onSelected: (a) => _onLessonAction(l, data, module, lesson, a),
        itemBuilder: (_) => [
          if (index > 0)
            PopupMenuItem(value: _ItemAction.moveUp, child: Text(l.moveUp)),
          if (index < lessons.length - 1)
            PopupMenuItem(
                value: _ItemAction.moveDown, child: Text(l.moveDown)),
          PopupMenuItem(value: _ItemAction.delete, child: Text(l.delete)),
        ],
      ),
    );
  }
}

/// Hộp thoại nhập tiêu đề (bắt buộc) và tuỳ chọn mô tả. Sở hữu controller
/// của nó (dispose cùng widget). Trả về (title, description).
class _TextFieldsDialog extends StatefulWidget {
  const _TextFieldsDialog({
    required this.title,
    required this.confirmLabel,
    this.initialTitle = '',
    this.initialDescription = '',
    this.withDescription = false,
  });

  final String title;
  final String confirmLabel;
  final String initialTitle;
  final String initialDescription;
  final bool withDescription;

  @override
  State<_TextFieldsDialog> createState() => _TextFieldsDialogState();
}

class _TextFieldsDialogState extends State<_TextFieldsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.initialTitle);
  late final TextEditingController _description =
      TextEditingController(text: widget.initialDescription);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, (_title.text.trim(), _description.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(labelText: l.title),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.titleRequired : null,
            ),
            if (widget.withDescription)
              TextFormField(
                controller: _description,
                decoration: InputDecoration(labelText: l.description),
                minLines: 1,
                maxLines: 3,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.course, required this.progress, required this.l});

  final Course course;
  final CourseProgress? progress;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = progress?.ratio ?? 0.0;
    final done = progress?.isDone ?? false;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.description.isNotEmpty) ...[
              Text(course.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            Text(
              done
                  ? '${courseStatusLabel(l, course.status)} · ${l.courseCompleted}'
                  : courseStatusLabel(l, course.status),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Text(
                '${l.lessonsCompleted}: '
                '${progress?.completedLessons ?? 0}/${progress?.totalLessons ?? 0}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: ratio,
              semanticsLabel: l.learningProgress,
              semanticsValue: formatPercent(ratio),
            ),
          ],
        ),
      ),
    );
  }
}
