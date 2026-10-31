import 'package:appflowy_editor/appflowy_editor.dart' show EditorState;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_lesson.dart';
import '../domain/models/model_lesson_progress.dart';
import '../domain/models/model_note.dart';
import '../domain/repositories/learning_repository.dart';
import '../domain/repositories/note_repository.dart';
import '../screen_notes/page_note_picker.dart';
import '../screen_tasks/component_widgets/attached_notes_view.dart';
import '../shared/appflowy_content_editor.dart';
import '../shared/appflowy_description.dart';
import 'learning_labels.dart';

/// Màn một bài học (Core Track C7). Mở bài → ghi nhận tiến độ (notStarted →
/// inProgress, cập nhật lastOpenedAt). Chế độ xem: nội dung appflowy (chỉ
/// đọc), liên kết ngoài, ghi chú liên kết, nút "Đánh dấu hoàn thành". Chế độ
/// sửa: tiêu đề, nội dung (soạn được), thêm/gỡ liên kết và ghi chú.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LearningRepository _repository =
      context.read<LearningRepository>();

  bool _loading = true;
  Lesson? _lesson;
  LessonProgress? _progress;
  EditorState? _editorState;

  bool _editing = false;
  final TextEditingController _titleController = TextEditingController();
  List<LessonLink> _links = const [];
  List<String> _noteIds = const [];
  final Map<String, String> _noteTitles = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final lesson = await _repository.getLesson(widget.lessonId);
    LessonProgress? progress;
    if (lesson != null) {
      progress = await _repository.markLessonOpened(lesson.id);
    }
    if (!mounted) return;
    setState(() {
      _lesson = lesson;
      _progress = progress;
      _loading = false;
      if (lesson != null) _resetFrom(lesson);
    });
  }

  /// Dựng lại trạng thái soạn thảo từ bài đã lưu (dùng khi mở / hủy sửa).
  void _resetFrom(Lesson lesson) {
    _editorState?.dispose();
    _editorState = AppFlowyDescription.buildEditorState(
        docJson: lesson.contentJson, plainText: '')
      ..editable = _editing;
    _titleController.text = lesson.title;
    _links = List.of(lesson.links);
    _noteIds = List.of(lesson.noteIds);
  }

  @override
  void dispose() {
    _editorState?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // ---------------- Progress ----------------

  Future<void> _toggleComplete() async {
    final lesson = _lesson;
    if (lesson == null || _busy) return;
    setState(() => _busy = true);
    final completed = _progress?.status == LessonStatus.completed;
    final next = completed
        ? await _repository.markLessonIncomplete(lesson.id)
        : await _repository.markLessonCompleted(lesson.id);
    if (!mounted) return;
    setState(() {
      _progress = next;
      _busy = false;
    });
  }

  // ---------------- Edit mode ----------------

  void _startEdit() {
    setState(() {
      _editing = true;
      _editorState?.editable = true;
    });
    _loadNoteTitles();
  }

  void _cancelEdit() {
    final lesson = _lesson;
    if (lesson == null) return;
    setState(() {
      _editing = false;
      _resetFrom(lesson);
    });
  }

  Future<void> _save() async {
    final lesson = _lesson;
    final editorState = _editorState;
    if (lesson == null || editorState == null || _busy) return;
    setState(() => _busy = true);
    final updated = lesson.copyWith(
      title: _titleController.text.trim(),
      contentJson: AppFlowyDescription.encodeDoc(editorState),
      links: _links,
      noteIds: _noteIds,
      updateTimeStamp: DateTime.now(),
    );
    await _repository.updateLesson(updated);
    if (!mounted) return;
    setState(() {
      _lesson = updated;
      _editing = false;
      _busy = false;
      editorState.editable = false;
    });
  }

  Future<void> _loadNoteTitles() async {
    if (_noteIds.isEmpty) return;
    final notes = context.read<NoteRepository>();
    for (final id in _noteIds) {
      if (_noteTitles.containsKey(id)) continue;
      final note = await notes.getNote(id);
      if (note != null) _noteTitles[id] = note.title;
    }
    if (mounted) setState(() {});
  }

  Future<void> _addLink() async {
    final link = await showDialog<LessonLink>(
      context: context,
      builder: (_) => const _LinkDialog(),
    );
    if (link == null || !mounted) return;
    setState(() => _links = [..._links, link]);
  }

  Future<void> _attachNote() async {
    final note = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
          builder: (_) => NotePickerPage(excludeIds: _noteIds)),
    );
    if (note == null || !mounted) return;
    setState(() {
      _noteTitles[note.id] = note.title;
      if (!_noteIds.contains(note.id)) _noteIds = [..._noteIds, note.id];
    });
  }

  Future<void> _openLink(AppLocalizations l, LessonLink link) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(link.url),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.cannotOpenLink)));
    }
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final lesson = _lesson;
    final editorState = _editorState;
    if (lesson == null || editorState == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.lessonNotFound,
                style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final status = _progress?.status ?? LessonStatus.notStarted;
    final completed = status == LessonStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: _editing
            ? TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: l.title,
                  border: InputBorder.none,
                ),
                style: theme.textTheme.titleLarge,
              )
            : Text(
                lesson.title.isEmpty ? l.learningUntitled : lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: _editing
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l.cancel,
                  onPressed: _cancelEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: l.save,
                  onPressed: _busy ? null : _save,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l.editLesson,
                  onPressed: _startEdit,
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_editing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        completed
                            ? Icons.check_circle
                            : status == LessonStatus.inProgress
                                ? Icons.timelapse
                                : Icons.radio_button_unchecked,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(lessonStatusLabel(l, status),
                        style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AppFlowyContentEditor(
                  key: ValueKey((editorState, _editing)),
                  editorState: editorState,
                  editable: _editing,
                ),
              ),
            ),
            _attachments(l, theme),
          ],
        ),
      ),
      bottomNavigationBar: _editing
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: completed
                    ? OutlinedButton.icon(
                        onPressed: _busy ? null : _toggleComplete,
                        icon: const Icon(Icons.undo),
                        label: Text(l.markIncomplete),
                      )
                    : FilledButton.icon(
                        onPressed: _busy ? null : _toggleComplete,
                        icon: const Icon(Icons.check),
                        label: Text(l.markComplete),
                      ),
              ),
            ),
    );
  }

  /// Liên kết + ghi chú liên kết (đặt dưới nội dung, giới hạn chiều cao).
  Widget _attachments(AppLocalizations l, ThemeData theme) {
    final hasLinks = _links.isNotEmpty;
    final hasNotes = _noteIds.isNotEmpty;
    if (!_editing && !hasLinks && !hasNotes) return const SizedBox.shrink();

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Semantics(
            header: true,
            child: Text(text, style: theme.textTheme.titleSmall),
          ),
        );

    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.35),
      child: ListView(
        shrinkWrap: true,
        children: [
          const Divider(height: 1),
          if (hasLinks || _editing) header(l.lessonLinks),
          for (var i = 0; i < _links.length; i++)
            ListTile(
              leading: const ExcludeSemantics(child: Icon(Icons.link)),
              title: Text(
                _links[i].title.isEmpty ? _links[i].url : _links[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _links[i].title.isEmpty
                  ? null
                  : Text(_links[i].url,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: _editing ? null : () => _openLink(l, _links[i]),
              trailing: _editing
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: l.removeItem,
                      onPressed: () => setState(() {
                        _links = [..._links]..removeAt(i);
                      }),
                    )
                  : null,
            ),
          if (_editing)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: _addLink,
                  icon: const Icon(Icons.add_link),
                  label: Text(l.addLink),
                ),
              ),
            ),
          if (hasNotes || _editing) header(l.linkedNotes),
          if (!_editing && hasNotes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AttachedNotesView(noteIds: _noteIds),
            ),
          if (_editing)
            for (final id in _noteIds)
              ListTile(
                leading: const ExcludeSemantics(
                    child: Icon(Icons.sticky_note_2_outlined)),
                title: Text(
                  (_noteTitles[id] ?? '').isEmpty
                      ? l.learningUntitled
                      : _noteTitles[id]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: l.removeItem,
                  onPressed: () => setState(() {
                    _noteIds = _noteIds.where((x) => x != id).toList();
                  }),
                ),
              ),
          if (_editing)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: _attachNote,
                  icon: const Icon(Icons.note_add_outlined),
                  label: Text(l.attachNote),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hộp thoại thêm liên kết (tiêu đề tuỳ chọn + URL http/https bắt buộc).
class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  /// Chỉ chấp nhận scheme http/https và host không rỗng.
  static bool isValidUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
        context, LessonLink(title: _title.text.trim(), url: _url.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.addLink),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l.title),
            ),
            TextFormField(
              controller: _url,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l.linkUrl),
              validator: (v) => isValidUrl(v ?? '') ? null : l.invalidUrl,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(l.add)),
      ],
    );
  }
}
