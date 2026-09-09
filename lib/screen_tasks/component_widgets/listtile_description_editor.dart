import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';

/// Ô nhập MÔ TẢ dùng trình soạn thảo block appflowy_editor (thay cho TextField).
///
/// Widget CHỈ hiển thị/soạn thảo trên [editorState] do trang cha tạo và giữ
/// (trang cha chịu trách nhiệm tạo bằng [AppFlowyDescription.buildEditorState],
/// dispose, và lưu bằng encodeDoc/extractPlainText). Đặt trong một khung chiều
/// cao cố định để dùng được bên trong form cuộn.
class DescriptionEditorTile extends StatelessWidget {
  const DescriptionEditorTile({
    super.key,
    required this.editorState,
    this.height = 220,
  });

  final EditorState editorState;
  final double height;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, right: 20.0),
              child: Icon(Icons.description_outlined),
            ),
            Expanded(
              child: Text(
                localizations!.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
            ),
          ],
        ),
        SizedBox(
          height: height,
          child: AppFlowyEditor(
            editorState: editorState,
            shrinkWrap: false,
            editorStyle: EditorStyle.desktop(
              cursorColor: theme.colorScheme.primary,
              selectionColor: theme.colorScheme.primary.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              textStyleConfiguration: TextStyleConfiguration(
                text: theme.textTheme.bodyMedium ??
                    const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        const Divider(height: 4),
      ],
    );
  }
}
