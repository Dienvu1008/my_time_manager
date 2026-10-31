// Model Lesson (Core Track C7 — Learning system)
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Một liên kết ngoài của bài học (lưu trong cột JSON `lessons.links`).
class LessonLink extends Equatable {
  final String title;
  final String url;

  const LessonLink({required this.title, required this.url});

  Map<String, dynamic> toJson() => {'title': title, 'url': url};

  /// Đọc một phần tử JSON; trả về null nếu không hợp lệ (thiếu url).
  static LessonLink? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url'];
    if (url is! String || url.isEmpty) return null;
    final title = raw['title'];
    return LessonLink(title: title is String ? title : '', url: url);
  }

  @override
  List<Object?> get props => [title, url];
}

/// Một bài học thuộc một chương (qua [moduleId]). Nội dung [contentJson] là
/// JSON tài liệu appflowy_editor (cùng định dạng với Note); chuỗi rỗng = chưa
/// có nội dung. [links] / [noteIds] lưu dạng JSON TEXT (cùng quy ước với
/// `tasks.noteIds`); dữ liệu hỏng/NULL được đọc thành danh sách rỗng.
/// `deviceId` do DAO gắn khi insert.
class Lesson extends Equatable {
  final String id;
  final String moduleId;
  final String title;
  final String contentJson;
  final List<LessonLink> links;
  final List<String> noteIds;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updateTimeStamp;

  Lesson({
    String? id,
    required this.moduleId,
    required this.title,
    String? contentJson,
    List<LessonLink>? links,
    List<String>? noteIds,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updateTimeStamp,
  })  : id = id ?? const Uuid().v4(),
        contentJson = contentJson ?? '',
        links = List.unmodifiable(links ?? const <LessonLink>[]),
        noteIds = List.unmodifiable(noteIds ?? const <String>[]),
        createdAt = createdAt ?? DateTime.now(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moduleId': moduleId,
      'title': title,
      'contentJson': contentJson,
      'links': jsonEncode(links.map((l) => l.toJson()).toList()),
      'noteIds': jsonEncode(noteIds),
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return Lesson(
      id: map['id'] as String,
      moduleId: map['moduleId'] as String,
      title: (map['title'] as String?) ?? '',
      contentJson: map['contentJson'] as String?,
      links: decodeLinks(map['links']),
      noteIds: decodeNoteIds(map['noteIds']),
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: _parseDate(map['createdAt']) ?? now,
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? now,
    );
  }

  /// Giải mã cột `links`; dữ liệu hỏng/NULL → `[]`, bỏ phần tử không hợp lệ.
  static List<LessonLink> decodeLinks(Object? raw) {
    final list = _decodeList(raw);
    return [
      for (final e in list)
        if (LessonLink.tryFromJson(e) case final link?) link,
    ];
  }

  /// Giải mã cột `noteIds`; dữ liệu hỏng/NULL → `[]`, bỏ phần tử không phải chuỗi.
  static List<String> decodeNoteIds(Object? raw) {
    final list = _decodeList(raw);
    return [
      for (final e in list)
        if (e is String && e.isNotEmpty) e,
    ];
  }

  static List<dynamic> _decodeList(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : const [];
    } catch (_) {
      return const [];
    }
  }

  Lesson copyWith({
    String? title,
    String? contentJson,
    List<LessonLink>? links,
    List<String>? noteIds,
    int? sortOrder,
    DateTime? updateTimeStamp,
  }) {
    return Lesson(
      id: id,
      moduleId: moduleId,
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      links: links ?? this.links,
      noteIds: noteIds ?? this.noteIds,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  @override
  String toString() => 'Lesson(id: $id, moduleId: $moduleId, title: $title)';

  @override
  List<Object?> get props => [
        id,
        moduleId,
        title,
        contentJson,
        links,
        noteIds,
        sortOrder,
        createdAt,
        updateTimeStamp,
      ];
}
