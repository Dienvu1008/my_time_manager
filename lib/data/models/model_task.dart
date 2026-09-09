// Model Task hợp nhất.
//
// Trước đây app có 3 model riêng: Task (thường), MeasurableTask (có mục tiêu đo
// lường) và TaskWithSubtasks (có công việc con). Nay gộp tất cả thành MỘT model
// [Task] duy nhất:
//   - `isMeasurable` bật => task có mục tiêu đo lường (target/unit/đã làm).
//   - `subtasks` không rỗng => task có công việc con.
// Mỗi [Subtask] cũng có thể tự nó là loại đo lường và được lập kế hoạch riêng
// (TimeInterval trỏ tới subtask qua subtaskId).
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Kiểu mục tiêu cho task/subtask đo lường.
enum TargetType { atLeast, atMost, about }

/// JSON không hỗ trợ Infinity/-Infinity/NaN. Vì [Subtask] được lưu dưới dạng
/// chuỗi JSON (nằm trong cột `subtasks`), ta mã hóa các giá trị này thành chuỗi
/// sentinel khi encode và khôi phục khi decode.
Object _encodeDouble(double value) {
  if (value == double.infinity) return 'Infinity';
  if (value == double.negativeInfinity) return '-Infinity';
  if (value.isNaN) return 'NaN';
  return value;
}

double _decodeDouble(dynamic value, double fallback) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) {
    switch (value) {
      case 'Infinity':
        return double.infinity;
      case '-Infinity':
        return double.negativeInfinity;
      case 'NaN':
        return double.nan;
      default:
        return double.tryParse(value) ?? fallback;
    }
  }
  return fallback;
}

/// Một công việc con. Được nâng cấp để: có id riêng (phục vụ lập kế hoạch
/// riêng), có thể là loại đo lường, và có trạng thái hoàn thành.
class Subtask {
  String id;
  String title;
  bool isCompleted;

  /// True => subtask này là loại đo lường (có target/unit/đã làm).
  bool isMeasurable;
  TargetType targetType;
  double targetAtLeast;
  double targetAtMost;
  String unit;
  double howMuchHasBeenDone;

  Subtask({
    String? id,
    required this.title,
    bool? isCompleted,
    bool? isMeasurable,
    TargetType? targetType,
    double? targetAtLeast,
    double? targetAtMost,
    String? unit,
    double? howMuchHasBeenDone,
  })  : id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false,
        isMeasurable = isMeasurable ?? false,
        targetType = targetType ?? TargetType.about,
        targetAtLeast = targetAtLeast ?? double.negativeInfinity,
        targetAtMost = targetAtMost ?? double.infinity,
        unit = unit ?? '',
        howMuchHasBeenDone = howMuchHasBeenDone ?? 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      // Giữ khóa cũ 'isSubtaskCompleted' để tương thích dữ liệu/đọc quen thuộc.
      'isSubtaskCompleted': isCompleted ? 1 : 0,
      'isMeasurable': isMeasurable ? 1 : 0,
      'targetType': targetType.index,
      'targetAtLeast': _encodeDouble(targetAtLeast),
      'targetAtMost': _encodeDouble(targetAtMost),
      'unit': unit,
      'howMuchHasBeenDone': _encodeDouble(howMuchHasBeenDone),
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      isCompleted: map['isSubtaskCompleted'] == 1 || map['isCompleted'] == 1,
      isMeasurable: map['isMeasurable'] == 1,
      targetType: map['targetType'] != null
          ? TargetType.values[map['targetType'] as int]
          : TargetType.about,
      targetAtLeast:
          _decodeDouble(map['targetAtLeast'], double.negativeInfinity),
      targetAtMost: _decodeDouble(map['targetAtMost'], double.infinity),
      unit: map['unit'] as String? ?? '',
      howMuchHasBeenDone: _decodeDouble(map['howMuchHasBeenDone'], 0.0),
    );
  }

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isMeasurable,
    TargetType? targetType,
    double? targetAtLeast,
    double? targetAtMost,
    String? unit,
    double? howMuchHasBeenDone,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isMeasurable: isMeasurable ?? this.isMeasurable,
      targetType: targetType ?? this.targetType,
      targetAtLeast: targetAtLeast ?? this.targetAtLeast,
      targetAtMost: targetAtMost ?? this.targetAtMost,
      unit: unit ?? this.unit,
      howMuchHasBeenDone: howMuchHasBeenDone ?? this.howMuchHasBeenDone,
    );
  }
}

class Task extends Equatable {
  String id;

  /// Danh sách mà task thuộc về. Null = task "tự do" (hiển thị ở cấp cao nhất
  /// của màn Overview, không nằm trong danh sách nào).
  final String? taskListId;
  final String title;
  final bool isCompleted;
  final bool isImportant;
  final String description;

  /// JSON document appflowy_editor cho mô tả có định dạng (rỗng = chưa có).
  final String descriptionDoc;
  final String location;
  final Color color;
  final List<String> tags;
  final List<String> dataFiles;

  /// Danh sách id các ghi chú (Note) được đính kèm.
  final List<String> noteIds;

  // --- Phần đo lường (chỉ dùng khi isMeasurable == true) ---
  final bool isMeasurable;
  final TargetType targetType;
  final double targetAtLeast;
  final double targetAtMost;
  final String unit;
  final double howMuchHasBeenDone;

  // --- Công việc con ---
  final List<Subtask> subtasks;

  final DateTime updateTimeStamp;

  Task({
    String? id,
    this.taskListId,
    required this.title,
    bool? isCompleted,
    bool? isImportant,
    String? description,
    String? descriptionDoc,
    String? location,
    Color? color,
    List<String>? tags,
    List<String>? dataFiles,
    List<String>? noteIds,
    bool? isMeasurable,
    TargetType? targetType,
    double? targetAtLeast,
    double? targetAtMost,
    String? unit,
    double? howMuchHasBeenDone,
    List<Subtask>? subtasks,
    DateTime? updateTimeStamp,
  })  : id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false,
        isImportant = isImportant ?? false,
        description = description ?? '',
        descriptionDoc = descriptionDoc ?? '',
        location = location ?? '',
        color = color ?? Colors.white,
        tags = tags ?? [],
        dataFiles = dataFiles ?? [],
        noteIds = noteIds ?? [],
        isMeasurable = isMeasurable ?? false,
        targetType = targetType ?? TargetType.about,
        targetAtLeast = targetAtLeast ?? double.negativeInfinity,
        targetAtMost = targetAtMost ?? double.infinity,
        unit = unit ?? '',
        howMuchHasBeenDone = howMuchHasBeenDone ?? 0.0,
        subtasks = subtasks ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  /// True nếu task có công việc con.
  bool get hasSubtasks => subtasks.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'description': description,
      'descriptionDoc': descriptionDoc,
      'location': location,
      'color': color.value,
      'tags': jsonEncode(tags),
      'dataFiles': jsonEncode(dataFiles),
      'noteIds': jsonEncode(noteIds),
      'isMeasurable': isMeasurable ? 1 : 0,
      'targetType': targetType.index,
      'targetAtLeast': targetAtLeast,
      'targetAtMost': targetAtMost,
      'unit': unit,
      'howMuchHasBeenDone': howMuchHasBeenDone,
      'subtasks':
          jsonEncode(subtasks.map((subtask) => subtask.toMap()).toList()),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String?,
      taskListId: map['taskListId'] as String?,
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] == 1,
      isImportant: map['isImportant'] == 1,
      description: map['description'] as String?,
      descriptionDoc: map['descriptionDoc'] as String?,
      location: map['location'] as String?,
      color: Color(map['color'] as int),
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags']))
          : <String>[],
      dataFiles: map['dataFiles'] != null
          ? List<String>.from(jsonDecode(map['dataFiles']))
          : <String>[],
      noteIds: map['noteIds'] != null
          ? List<String>.from(jsonDecode(map['noteIds']))
          : <String>[],
      isMeasurable: map['isMeasurable'] == 1,
      targetType: map['targetType'] != null
          ? TargetType.values[map['targetType'] as int]
          : TargetType.about,
      targetAtLeast:
          (map['targetAtLeast'] as num?)?.toDouble() ?? double.negativeInfinity,
      targetAtMost:
          (map['targetAtMost'] as num?)?.toDouble() ?? double.infinity,
      unit: map['unit'] as String? ?? '',
      howMuchHasBeenDone: (map['howMuchHasBeenDone'] as num?)?.toDouble() ?? 0.0,
      subtasks: map['subtasks'] != null
          ? List<Subtask>.from(
              jsonDecode(map['subtasks']).map((m) => Subtask.fromMap(m)))
          : <Subtask>[],
      updateTimeStamp: map['updateTimeStamp'] != null
          ? DateTime.parse(map['updateTimeStamp'])
          : null,
    );
  }

  Task copyWith({
    String? id,
    String? taskListId,
    bool clearTaskListId = false,
    String? title,
    bool? isCompleted,
    bool? isImportant,
    String? description,
    String? descriptionDoc,
    String? location,
    Color? color,
    List<String>? tags,
    List<String>? dataFiles,
    List<String>? noteIds,
    bool? isMeasurable,
    TargetType? targetType,
    double? targetAtLeast,
    double? targetAtMost,
    String? unit,
    double? howMuchHasBeenDone,
    List<Subtask>? subtasks,
    DateTime? updateTimeStamp,
  }) {
    return Task(
      id: id ?? this.id,
      taskListId: clearTaskListId ? null : (taskListId ?? this.taskListId),
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      description: description ?? this.description,
      descriptionDoc: descriptionDoc ?? this.descriptionDoc,
      location: location ?? this.location,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      dataFiles: dataFiles ?? this.dataFiles,
      noteIds: noteIds ?? this.noteIds,
      isMeasurable: isMeasurable ?? this.isMeasurable,
      targetType: targetType ?? this.targetType,
      targetAtLeast: targetAtLeast ?? this.targetAtLeast,
      targetAtMost: targetAtMost ?? this.targetAtMost,
      unit: unit ?? this.unit,
      howMuchHasBeenDone: howMuchHasBeenDone ?? this.howMuchHasBeenDone,
      subtasks: subtasks ?? this.subtasks,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
    );
  }

  String toJson() => json.encode(toMap());
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));

  @override
  String toString() {
    return '''Task(
      id: $id, 
      title: $title, 
      description: $description, 
      color: $color, 
      isCompleted : $isCompleted, 
      isMeasurable: $isMeasurable,
      subtasks: ${subtasks.length},
      taskListId: $taskListId)''';
  }

  @override
  List<Object?> get props =>
      [id, taskListId, title, description, isCompleted, isMeasurable];
}
