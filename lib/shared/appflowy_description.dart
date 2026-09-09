import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';

/// Tiện ích cho phần MÔ TẢ (description) dùng trình soạn thảo appflowy_editor.
///
/// Chiến lược "lưu song song" (xem thiết kế): mỗi đối tượng lưu 2 dạng:
/// - `description`: PLAIN TEXT — dùng cho hiển thị nhanh (card/lịch), so sánh,
///   backup, đồng bộ; luôn được trích ra từ document khi lưu.
/// - `descriptionDoc`: chuỗi JSON của một Document appflowy_editor — dùng để
///   soạn thảo có định dạng.
class AppFlowyDescription {
  AppFlowyDescription._();

  /// Dựng [EditorState] để mở trong trình soạn thảo.
  ///
  /// Ưu tiên [docJson] (JSON document đã lưu). Nếu rỗng/hỏng thì dựng từ
  /// [plainText] cũ (mỗi dòng thành một đoạn). Nếu cả hai rỗng -> document trống.
  static EditorState buildEditorState({
    required String docJson,
    required String plainText,
  }) {
    // 1) Có sẵn JSON document -> dùng luôn.
    if (docJson.trim().isNotEmpty) {
      try {
        final map = jsonDecode(docJson) as Map<String, dynamic>;
        return EditorState(document: Document.fromJson(map));
      } catch (_) {
        // JSON hỏng -> rơi xuống nhánh plain text.
      }
    }
    // 2) Chưa có JSON nhưng có plain text cũ -> dựng document từ các dòng.
    if (plainText.trim().isNotEmpty) {
      final document = Document.blank();
      final lines = plainText.split('\n');
      var index = 0;
      for (final line in lines) {
        document.insert(
          [index],
          [paragraphNode(text: line)],
        );
        index++;
      }
      return EditorState(document: document);
    }
    // 3) Trống hoàn toàn.
    return EditorState.blank(withInitialText: true);
  }

  /// Chuỗi JSON của document (để lưu vào cột descriptionDoc).
  static String encodeDoc(EditorState editorState) {
    return jsonEncode(editorState.document.toJson());
  }

  /// Trích PLAIN TEXT từ document (để lưu vào cột description). Ghép text của
  /// từng node theo dòng, bỏ dòng trống thừa ở đầu/cuối.
  static String extractPlainText(EditorState editorState) {
    final buffer = <String>[];
    _collectText(editorState.document.root, buffer);
    // Loại các dòng trống ở đầu/cuối, giữ nguyên dòng trống ở giữa.
    while (buffer.isNotEmpty && buffer.first.trim().isEmpty) {
      buffer.removeAt(0);
    }
    while (buffer.isNotEmpty && buffer.last.trim().isEmpty) {
      buffer.removeLast();
    }
    return buffer.join('\n');
  }

  static void _collectText(Node node, List<String> out) {
    final delta = node.delta;
    if (delta != null) {
      out.add(delta.toPlainText());
    }
    for (final child in node.children) {
      _collectText(child, out);
    }
  }
}
