// Model GoalLink (Core Track C5 — Goal / Milestone foundations)
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Các loại thực thể có thể liên kết với một mục tiêu.
///
/// Dùng String (không phải enum Dart) để các bản ghi do phiên bản sau ghi ra
/// (vd. 'calendarEvent', 'habit', 'note') không làm hỏng [GoalLink.fromMap]
/// trên bản build cũ hơn.
///
/// 'course' (C7): liên kết khóa học chỉ mang tính thông tin — tiến độ khóa học
/// KHÔNG tính vào tiến độ mục tiêu (GoalProgressService chỉ đếm 'task').
class GoalEntityType {
  GoalEntityType._();

  static const String task = 'task';
  static const String course = 'course';
}

/// Liên kết một thực thể ([entityType] + [entityId]) với một [Goal], tuỳ chọn
/// gắn vào một [Milestone] của mục tiêu đó ([milestoneId] null = liên kết trực
/// tiếp với mục tiêu). `deviceId` do DAO gắn khi insert.
class GoalLink extends Equatable {
  final String id;
  final String goalId;
  final String? milestoneId;
  final String entityType;
  final String entityId;
  final DateTime createdAt;

  GoalLink({
    String? id,
    required this.goalId,
    this.milestoneId,
    required this.entityType,
    required this.entityId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'milestoneId': milestoneId,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GoalLink.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    return GoalLink(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      milestoneId: map['milestoneId'] as String?,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      createdAt: createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw.toString()),
    );
  }

  @override
  String toString() => 'GoalLink(id: $id, goalId: $goalId, '
      'milestoneId: $milestoneId, $entityType:$entityId)';

  @override
  List<Object?> get props =>
      [id, goalId, milestoneId, entityType, entityId, createdAt];
}
