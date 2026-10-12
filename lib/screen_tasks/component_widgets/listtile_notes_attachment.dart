import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/model_note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../screen_notes/page_note_editor.dart';
import '../../screen_notes/page_note_picker.dart';

/// ListTile đính kèm GHI CHÚ (Note) vào Task/MeasurableTask/TaskWithSubtasks/
/// TimeInterval — tương tự đính kèm file.
///
/// Trang cha giữ danh sách [noteIds] trong state và nhận danh sách mới qua
/// [onChanged] mỗi khi người dùng thêm/gỡ. Nhấn vào một ghi chú sẽ mở
/// [NoteEditorPage] để xem/sửa.
class NotesAttachmentListTile extends StatefulWidget {
  const NotesAttachmentListTile({
    super.key,
    required this.noteIds,
    required this.onChanged,
  });

  final List<String> noteIds;
  final ValueChanged<List<String>> onChanged;

  @override
  State<NotesAttachmentListTile> createState() =>
      _NotesAttachmentListTileState();
}

class _NotesAttachmentListTileState extends State<NotesAttachmentListTile> {
  late final NoteRepository _noteRepository = context.read<NoteRepository>();

  /// Cache tiêu đề ghi chú theo id để hiển thị nhanh (nạp lại khi noteIds đổi).
  Map<String, Note> _notesById = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void didUpdateWidget(covariant NotesAttachmentListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteIds != widget.noteIds) {
      _loadNotes();
    }
  }

  Future<void> _loadNotes() async {
    if (widget.noteIds.isEmpty) {
      setState(() => _notesById = {});
      return;
    }
    setState(() => _loading = true);
    final map = <String, Note>{};
    for (final id in widget.noteIds) {
      final note = await _noteRepository.getNote(id);
      if (note != null) map[id] = note;
    }
    if (!mounted) return;
    setState(() {
      _notesById = map;
      _loading = false;
    });
  }

  Future<void> _pickNote() async {
    final selected = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => NotePickerPage(excludeIds: widget.noteIds),
      ),
    );
    if (selected == null) return;
    if (widget.noteIds.contains(selected.id)) return;
    final updated = [...widget.noteIds, selected.id];
    widget.onChanged(updated);
  }

  void _removeNote(String id) {
    final updated = widget.noteIds.where((e) => e != id).toList();
    widget.onChanged(updated);
  }

  /// Mở ghi chú để xem/sửa; nạp lại tiêu đề nếu có thay đổi.
  Future<void> _openNote(String id) async {
    final note = _notesById[id] ?? await _noteRepository.getNote(id);
    if (note == null) {
      // Ghi chú đã bị xóa ở nơi khác -> gỡ khỏi danh sách đính kèm.
      _removeNote(id);
      return;
    }
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );
    if (changed == true) {
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.only(left: 0.0, right: 4.0),
            child: Icon(Icons.sticky_note_2_outlined),
          ),
          title: const Text('Ghi chú đính kèm'),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Đính kèm ghi chú',
            onPressed: _pickNote,
          ),
          onTap: _pickNote,
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        ...widget.noteIds.map((id) {
          final note = _notesById[id];
          final title = note == null
              ? '(Đang tải...)'
              : (note.title.isEmpty ? '(Không tiêu đề)' : note.title);
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 40, right: 4),
            leading: const Icon(Icons.description_outlined, size: 20),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Gỡ đính kèm',
              onPressed: () => _removeNote(id),
            ),
            onTap: () => _openNote(id),
          );
        }),
        const Divider(height: 4),
      ],
    );
  }
}
