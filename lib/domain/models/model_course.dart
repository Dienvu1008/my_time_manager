// Model Course (Core Track C7 — Learning system)
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Ý định học của người dùng với một khóa học. Lưu xuống DB dưới dạng `.name`.
///
/// KHÔNG có trạng thái "completed" lưu trữ: hoàn thành được TÍNH bởi
/// LearningProgressService (khóa học có ≥1 bài và mọi bài đều hoàn thành).
enum CourseStatus {
  active,
  paused;

  /// Đọc từ chuỗi đã lưu; giá trị null/không xác định → [CourseStatus.active].
  static CourseStatus parse(Object? raw) {
    for (final s in CourseStatus.values) {
      if (s.name == raw) return s;
    }
    return CourseStatus.active;
  }
}

/// Nguồn gốc của khóa học (chuẩn bị cho C9 — AI sinh khóa học).
enum CourseSource {
  manual,
  aiGenerated;

  /// Đọc từ chuỗi đã lưu; giá trị null/không xác định → [CourseSource.manual].
  static CourseSource parse(Object? raw) {
    for (final s in CourseSource.values) {
      if (s.name == raw) return s;
    }
    return CourseSource.manual;
  }
}

/// Một khóa học (bảng `courses`). Khóa học → chương (CourseModule) → bài học
/// (Lesson); tiến độ chỉ lưu theo bài (LessonProgress), tiến độ chương/khóa
/// được TÍNH.
///
/// `isDeleted/deletedAt/isArchived/archivedAt` chỉ được đọc từ DB; [toMap]
/// KHÔNG ghi các cột này — các phương thức soft-delete/archive của DAO quản lý
/// chúng (giống projects). `deviceId` do DAO gắn khi insert.
class Course extends Equatable {
  final String id;
  final String title;
  final String description;
  final Color color;
  final CourseSource source;
  final CourseStatus status;
  final DateTime createdAt;
  final DateTime updateTimeStamp;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isArchived;
  final DateTime? archivedAt;

  Course({
    String? id,
    required this.title,
    String? description,
    Color? color,
    CourseSource? source,
    CourseStatus? status,
    DateTime? createdAt,
    DateTime? updateTimeStamp,
    this.isDeleted = false,
    this.deletedAt,
    this.isArchived = false,
    this.archivedAt,
  })  : id = id ?? const Uuid().v4(),
        description = description ?? '',
        color = color ?? Colors.white,
        source = source ?? CourseSource.manual,
        status = status ?? CourseStatus.active,
        createdAt = createdAt ?? DateTime.now(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color.toARGB32(),
      'source': source.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return Course(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      source: CourseSource.parse(map['source']),
      status: CourseStatus.parse(map['status']),
      createdAt: _parseDate(map['createdAt']) ?? now,
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? now,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      deletedAt: _parseDate(map['deletedAt']),
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      archivedAt: _parseDate(map['archivedAt']),
    );
  }

  Course copyWith({
    String? title,
    String? description,
    Color? color,
    CourseSource? source,
    CourseStatus? status,
    DateTime? updateTimeStamp,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      source: source ?? this.source,
      status: status ?? this.status,
      createdAt: createdAt,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      isArchived: isArchived,
      archivedAt: archivedAt,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  @override
  String toString() => 'Course(id: $id, title: $title, status: ${status.name})';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        color,
        source,
        status,
        createdAt,
        updateTimeStamp,
        isDeleted,
        deletedAt,
        isArchived,
        archivedAt,
      ];
}
