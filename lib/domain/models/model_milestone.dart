// Model Milestone (Core Track C5 — Goal / Milestone foundations)
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Một cột mốc thuộc một [Goal] (qua [goalId]). Cột mốc chỉ được hiển thị
/// thông qua mục tiêu cha nên không có cột soft-delete/archive riêng.
///
/// [isCompleted] là cờ hoàn thành thủ công; tiến độ theo task liên kết được
/// TÍNH bởi GoalProgressService (không lưu). `deviceId` do DAO gắn khi insert.
class Milestone extends Equatable {
  final String id;
  final String goalId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;
  final DateTime updateTimeStamp;

  Milestone({
    String? id,
    required this.goalId,
    required this.title,
    String? description,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.sortOrder = 0,
    DateTime? updateTimeStamp,
  })  : id = id ?? const Uuid().v4(),
        description = description ?? '',
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'sortOrder': sortOrder,
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      dueDate: _parseDate(map['dueDate']),
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      completedAt: _parseDate(map['completedAt']),
      sortOrder: map['sortOrder'] as int? ?? 0,
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? DateTime.now(),
    );
  }

  Milestone copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? sortOrder,
    DateTime? updateTimeStamp,
  }) {
    return Milestone(
      id: id,
      goalId: goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      sortOrder: sortOrder ?? this.sortOrder,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  @override
  String toString() =>
      'Milestone(id: $id, goalId: $goalId, title: $title, done: $isCompleted)';

  @override
  List<Object?> get props => [
        id,
        goalId,
        title,
        description,
        dueDate,
        isCompleted,
        completedAt,
        sortOrder,
        updateTimeStamp,
      ];
}
