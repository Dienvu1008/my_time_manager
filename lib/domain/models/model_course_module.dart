// Model CourseModule (Core Track C7 — Learning system)
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Một chương thuộc một [Course] (qua [courseId]). Chương chỉ hiển thị qua
/// khóa học cha nên không có cột soft-delete/archive riêng; xóa cứng cascade
/// xuống bài học và tiến độ. `deviceId` do DAO gắn khi insert.
class CourseModule extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updateTimeStamp;

  CourseModule({
    String? id,
    required this.courseId,
    required this.title,
    String? description,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updateTimeStamp,
  })  : id = id ?? const Uuid().v4(),
        description = description ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory CourseModule.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return CourseModule(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: _parseDate(map['createdAt']) ?? now,
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? now,
    );
  }

  CourseModule copyWith({
    String? title,
    String? description,
    int? sortOrder,
    DateTime? updateTimeStamp,
  }) {
    return CourseModule(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  @override
  String toString() =>
      'CourseModule(id: $id, courseId: $courseId, title: $title)';

  @override
  List<Object?> get props => [
        id,
        courseId,
        title,
        description,
        sortOrder,
        createdAt,
        updateTimeStamp,
      ];
}
