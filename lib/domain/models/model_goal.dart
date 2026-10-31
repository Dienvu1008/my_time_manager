// Model Goal (Core Track C5 — Goal / Milestone foundations)
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Trạng thái của một mục tiêu. Lưu xuống DB dưới dạng `.name` (TEXT).
enum GoalStatus {
  active,
  paused,
  completed,
  abandoned;

  /// Đọc từ chuỗi đã lưu; giá trị null/không xác định → [GoalStatus.active].
  static GoalStatus parse(Object? raw) {
    for (final s in GoalStatus.values) {
      if (s.name == raw) return s;
    }
    return GoalStatus.active;
  }
}

/// Một mục tiêu (Goal). "Kế hoạch" của mục tiêu KHÔNG phải một entity riêng:
/// kế hoạch = các [Milestone] của nó + các mục được liên kết (bảng
/// `goal_links`). Tiến độ luôn được TÍNH (GoalProgressService), không lưu.
///
/// `isDeleted/deletedAt/isArchived/archivedAt` chỉ được đọc từ DB; [toMap]
/// KHÔNG ghi các cột này — các phương thức soft-delete/archive của DAO quản lý
/// chúng (giống tasks/tasklists). `deviceId` do DAO gắn khi insert.
class Goal extends Equatable {
  final String id;
  final String title;
  final String description;
  final Color color;
  final GoalStatus status;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updateTimeStamp;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isArchived;
  final DateTime? archivedAt;

  Goal({
    String? id,
    required this.title,
    String? description,
    Color? color,
    GoalStatus? status,
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
        status = status ?? GoalStatus.active,
        createdAt = createdAt ?? DateTime.now(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color.toARGB32(),
      'status': status.name,
      'targetDate': targetDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return Goal(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      status: GoalStatus.parse(map['status']),
      targetDate: _parseDate(map['targetDate']),
      createdAt: _parseDate(map['createdAt']) ?? now,
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? now,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      deletedAt: _parseDate(map['deletedAt']),
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      archivedAt: _parseDate(map['archivedAt']),
    );
  }

  Goal copyWith({
    String? title,
    String? description,
    Color? color,
    GoalStatus? status,
    DateTime? targetDate,
    bool clearTargetDate = false,
    DateTime? updateTimeStamp,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
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
  String toString() => 'Goal(id: $id, title: $title, status: ${status.name})';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        color,
        status,
        targetDate,
        createdAt,
        updateTimeStamp,
        isDeleted,
        deletedAt,
        isArchived,
        archivedAt,
      ];
}
