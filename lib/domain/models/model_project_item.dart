// Model ProjectItem (Core Track C6 — Project Workspace)
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Các loại thực thể có thể thuộc một dự án.
///
/// Dùng String (không phải enum Dart) để các bản ghi do phiên bản sau ghi ra
/// (vd. 'habit', 'document') không làm hỏng [ProjectItem.fromMap] trên bản
/// build cũ hơn; read path bỏ qua loại không biết.
class ProjectEntityType {
  ProjectEntityType._();

  static const String taskList = 'taskList';
  static const String task = 'task';
  static const String note = 'note';
  static const String goal = 'goal';
  static const String calendarEvent = 'calendarEvent';

  /// Khóa học (C7).
  static const String course = 'course';

  /// Thói quen (Phase H1). CỐ Ý chưa nằm trong [supported] (chưa có UI chọn
  /// thói quen / workspace chưa hiển thị): ProjectWorkspaceService đếm các mục
  /// 'habit' vào ignoredItemCount. Trigger `delete_project_items_of_habit` dọn
  /// mục khi xóa cứng thói quen.
  static const String habit = 'habit';

  /// Các loại được hỗ trợ (C6 + 'course' từ C7).
  static const List<String> supported = [
    taskList,
    task,
    note,
    goal,
    calendarEvent,
    course,
  ];
}

/// Một thực thể ([entityType] + [entityId]) thuộc một [Project]. Quan hệ
/// nhiều-nhiều: một thực thể có thể thuộc nhiều dự án; mỗi bộ ba
/// (projectId, entityType, entityId) là duy nhất. `deviceId` do DAO gắn khi
/// insert.
class ProjectItem extends Equatable {
  final String id;
  final String projectId;
  final String entityType;
  final String entityId;
  final int sortOrder;
  final DateTime createdAt;

  ProjectItem({
    String? id,
    required this.projectId,
    required this.entityType,
    required this.entityId,
    this.sortOrder = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'entityType': entityType,
      'entityId': entityId,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectItem.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    return ProjectItem(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw.toString()),
    );
  }

  ProjectItem copyWith({int? sortOrder}) {
    return ProjectItem(
      id: id,
      projectId: projectId,
      entityType: entityType,
      entityId: entityId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'ProjectItem(id: $id, projectId: $projectId, '
      '$entityType:$entityId, sortOrder: $sortOrder)';

  @override
  List<Object?> get props =>
      [id, projectId, entityType, entityId, sortOrder, createdAt];
}
