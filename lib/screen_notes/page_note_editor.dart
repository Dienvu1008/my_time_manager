import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../data/database/database_manager.dart';
import '../data/models/model_note.dart';

/// Màn soạn thảo một ghi chú bằng trình soạn thảo block appflowy_editor.
///
/// [note] == null: tạo ghi chú mới. Khác null: sửa ghi chú hiện có.
/// Trả về (Navigator.pop) `true` nếu có thay đổi (đã lưu/xóa) để danh sách nạp lại.
class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final DatabaseManager _db = DatabaseManager();
  final TextEditingController _titleController = TextEditingController();
  late final EditorState _editorState;
  late Note _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note ?? Note();
    _titleController.text = _note.title;
    _editorState = _buildEditorState(_note.contentJson);
  }

  /// Dựng EditorState từ chuỗi JSON đã lưu, hoặc một document trống nếu chưa có
  /// / dữ liệu hỏng.
  EditorState _buildEditorState(String contentJson) {
    if (contentJson.trim().isEmpty) {
      return EditorState.blank(withInitialText: true);
    }
    try {
      final map = jsonDecode(contentJson) as Map<String, dynamic>;
      return EditorState(document: Document.fromJson(map));
    } catch (_) {
      return EditorState.blank(withInitialText: true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final contentJson = jsonEncode(_editorState.document.toJson());
    final updated = _note.copyWith(
      title: _titleController.text.trim(),
      contentJson: contentJson,
      updatedAt: DateTime.now(),
    );
    if (widget.note == null) {
      await _db.insertNote(updated);
    } else {
      await _db.updateNote(updated);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (widget.note == null) {
      Navigator.pop(context, false);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: Text('Xóa "${_note.title.isEmpty ? 'ghi chú này' : _note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _db.deleteNote(_note.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Tiêu đề ghi chú',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa',
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu',
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: AppFlowyEditor(
          editorState: _editorState,
          editorStyle: EditorStyle.desktop(
            cursorColor: Theme.of(context).colorScheme.primary,
            selectionColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            textStyleConfiguration: TextStyleConfiguration(
              text: Theme.of(context).textTheme.bodyMedium ??
                  const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
