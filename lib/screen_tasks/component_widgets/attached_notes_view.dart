import 'package:flutter/material.dart';

import '../../data/database/database_manager.dart';
import '../../data/models/model_note.dart';
import '../../screen_notes/page_note_editor.dart';

/// Hiển thị (chỉ đọc) danh sách GHI CHÚ đã đính kèm dưới dạng các dòng có thể
/// nhấn để mở [NoteEditorPage]. Dùng ở các card/chi tiết của Task/TimeInterval.
class AttachedNotesView extends StatefulWidget {
  const AttachedNotesView({
    super.key,
    required this.noteIds,
    this.color,
    this.textStyle,
  });

  final List<String> noteIds;
  final Color? color;
  final TextStyle? textStyle;

  @override
  State<AttachedNotesView> createState() => _AttachedNotesViewState();
}

class _AttachedNotesViewState extends State<AttachedNotesView> {
  final DatabaseManager _db = DatabaseManager();
  Map<String, Note> _notesById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AttachedNotesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteIds != widget.noteIds) _load();
  }

  Future<void> _load() async {
    final map = <String, Note>{};
    for (final id in widget.noteIds) {
      final note = await _db.note(id);
      if (note != null) map[id] = note;
    }
    if (!mounted) return;
    setState(() => _notesById = map);
  }

  Future<void> _open(Note note) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị các note thực sự tồn tại (bỏ id trỏ tới note đã xóa).
    final notes = widget.noteIds
        .map((id) => _notesById[id])
        .whereType<Note>()
        .toList();
    if (notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: notes.map((note) {
        return InkWell(
          onTap: () => _open(note),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, color: widget.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.title.isEmpty ? '(Không tiêu đề)' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.textStyle,
                  ),
                ),
                Icon(Icons.chevron_right, color: widget.color, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
