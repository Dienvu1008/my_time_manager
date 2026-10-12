import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Một ghi chú (note) dùng trình soạn thảo block appflowy_editor.
///
/// [contentJson] là chuỗi JSON của một Document appflowy_editor
/// (`editorState.document.toJson()`), lưu nguyên vào SQLite. Khi mở lại, dựng
/// `Document.fromJson(jsonDecode(contentJson))`.
class Note {
  Note({
    String? id,
    String? title,
    String? contentJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? '',
        contentJson = contentJson ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String id;
  String title;

  /// Nội dung dạng JSON document của appflowy_editor (chuỗi). Rỗng = note trống.
  String contentJson;

  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'contentJson': contentJson,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      contentJson: (map['contentJson'] as String?) ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Note copyWith({
    String? title,
    String? contentJson,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String toJson() => json.encode(toMap());
  factory Note.fromJson(String source) =>
      Note.fromMap(json.decode(source) as Map<String, dynamic>);
}
