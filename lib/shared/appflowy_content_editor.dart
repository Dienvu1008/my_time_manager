import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Trình soạn thảo/hiển thị nội dung appflowy_editor dùng chung (cấu hình
/// giống hệt màn soạn ghi chú). Dùng cho Note (NoteEditorPage) và bài học
/// (LessonScreen, C7). [editable] = false → chỉ xem.
class AppFlowyContentEditor extends StatelessWidget {
  const AppFlowyContentEditor({
    super.key,
    required this.editorState,
    this.editable = true,
  });

  final EditorState editorState;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return AppFlowyEditor(
      editorState: editorState,
      editable: editable,
      editorStyle: EditorStyle.desktop(
        cursorColor: Theme.of(context).colorScheme.primary,
        // ignore: deprecated_member_use
        selectionColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        textStyleConfiguration: TextStyleConfiguration(
          text: Theme.of(context).textTheme.bodyMedium ??
              const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
