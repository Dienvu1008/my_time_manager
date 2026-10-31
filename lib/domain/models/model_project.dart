// Model Project (Core Track C6 — Project Workspace)
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Trạng thái vòng đời của một dự án. Lưu xuống DB dưới dạng `.name` (TEXT).
enum ProjectStatus {
  active,
  onHold,
  completed,
  cancelled;

  /// Đọc từ chuỗi đã lưu; giá trị null/không xác định → [ProjectStatus.active].
  static ProjectStatus parse(Object? raw) {
    for (final s in ProjectStatus.values) {
      if (s.name == raw) return s;
    }
    return ProjectStatus.active;
  }
}

/// Một dự án (Project). Dự án là một entity MỚI (bảng `projects`), KHÔNG phải
/// TaskList. Các thành phần của dự án (danh sách, task, ghi chú, mục tiêu, sự
/// kiện) được liên kết qua bảng `project_items` ([ProjectItem]); workspace là
/// read model được TÍNH (ProjectWorkspaceService), không lưu.
///
/// `isDeleted/deletedAt/isArchived/archivedAt` chỉ được đọc từ DB; [toMap]
/// KHÔNG ghi các cột này — các phương thức soft-delete/archive của DAO quản lý
/// chúng (giống goals). `deviceId` do DAO gắn khi insert.
class Project extends Equatable {
  final String id;
  final String title;
  final String description;
  final Color color;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updateTimeStamp;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isArchived;
  final DateTime? archivedAt;

  Project({
    String? id,
    required this.title,
    String? description,
    Color? color,
    ProjectStatus? status,
    this.startDate,
    this.targetDate,
    DateTime? createdAt,
    DateTime? updateTimeStamp,
    this.isDeleted = false,
    this.deletedAt,
    this.isArchived = false,
    this.archivedAt,
  })  : id = id ?? const Uuid().v4(),
        description = description ?? '',
        color = color ?? Colors.white,
        status = status ?? ProjectStatus.active,
        createdAt = createdAt ?? DateTime.now(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color.toARGB32(),
      'status': status.name,
      'startDate': startDate?.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return Project(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      status: ProjectStatus.parse(map['status']),
      startDate: _parseDate(map['startDate']),
      targetDate: _parseDate(map['targetDate']),
      createdAt: _parseDate(map['createdAt']) ?? now,
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? now,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      deletedAt: _parseDate(map['deletedAt']),
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      archivedAt: _parseDate(map['archivedAt']),
    );
  }

  Project copyWith({
    String? title,
    String? description,
    Color? color,
    ProjectStatus? status,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? targetDate,
    bool clearTargetDate = false,
    DateTime? updateTimeStamp,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
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
  String toString() =>
      'Project(id: $id, title: $title, status: ${status.name})';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        color,
        status,
        startDate,
        targetDate,
        createdAt,
        updateTimeStamp,
        isDeleted,
        deletedAt,
        isArchived,
        archivedAt,
      ];
}
