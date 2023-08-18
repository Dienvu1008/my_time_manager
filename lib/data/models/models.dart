import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';

//part 'models.g.dart';

// Model Task
@JsonSerializable()
class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final Color color;
  late final bool isCompleted;
  final String taskListId;

  Task({
    required this.title,
    required this.taskListId,
    String? id,
    required this.description,
    required this.color,
    this.isCompleted = false,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color.value,
      'isCompleted': isCompleted ? 1 : 0,
      'taskListId': taskListId,
    };
  }

  String toJson() => json.encode(toMap());
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
  // Implement toString to make it easier to see information about
  // each task when using the print statement.
  @override
  String toString() {
    return '''Task(
      id: $id, 
      title: $title, 
      description: $description, 
      color: $color, 
      isCompleted : $isCompleted, 
      taskListId: $taskListId)''';
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],  //?? '',
      isCompleted: map['isCompleted'] == 1,
      color: Color(map['color']),
      taskListId: map['taskListId'],
    );
  }

  // Task copyWith({
  //   String? id,
  //   String? taskListId,
  //   String? title,
  //   String? description,
  //   bool? isCompleted,
  // }) {
  //   return Task(
  //     id: id ?? this.id,
  //     taskListId: taskListId ?? this.taskListId,
  //     title: title ?? this.title,
  //     description: description ?? this.description,
  //     isCompleted: isCompleted ?? this.isCompleted,
  //   );
  // }

  //static Task fromJson(JsonMap json) => _$TaskFromJson(json);

  //JsonMap toJson() => _$TaskToJson(this);

  @override
  List<Object?> get props => [id, taskListId, title, description, isCompleted];
}

//Model Task List
@JsonSerializable()
class TaskList extends Equatable {
  // static final tableTaskLists = "TaskLists";
  // static final dbId = 'id';
  // static final dbTitle = 'title';

  final String id;
  final String title;
  final String description;
  TaskList({
    required this.title,
    String? id,
    required this.description,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  TaskList copyWith({
    String? id,
    String? title,
    String? description,
  }) {
    return TaskList(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description);
  }

  //static TaskList fromJson(JsonMap json) => _$TaskListFromJson(json);

  //JsonMap toJson() => _$TaskListToJson(this);

  TaskList.create(this.id, this.title, this.description);

  TaskList.update(
      {required this.id, required this.title, required this.description}) {}

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }
  // : this.update(
  //     id: map[dbId],
  //     title: map[dbTitle],
  //   );
  String toJson() => json.encode(toMap());

  factory TaskList.fromJson(String source) =>
      TaskList.fromMap(json.decode(source));

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() =>
      'TaskList(id: $id, title: $title, description: $description)';

  @override
  List<Object?> get props => [id, title];
}

class TimeInterval {
  final String id;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isStartDateUndefined;
  bool isEndDateUndefined;
  bool isStartTimeUndefined;
  bool isEndTimeUndefined;
  int? startTimestamp;
  int? endTimestamp;

  TimeInterval({
    String? id,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isStartDateUndefined = false,
    this.isEndDateUndefined = false,
    this.isStartTimeUndefined = false,
    this.isEndTimeUndefined = false,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4() {
    if (isStartDateUndefined) {
      isStartTimeUndefined = true;
      startTimestamp = null;
    } else if (isStartTimeUndefined) {
      startTimestamp =
          DateTime(startDate!.year, startDate!.month, startDate!.day)
              .millisecondsSinceEpoch;
    } else {
      startTimestamp = DateTime(startDate!.year, startDate!.month,
              startDate!.day, startTime!.hour, startTime!.minute)
          .millisecondsSinceEpoch;
    }

    if (isEndDateUndefined) {
      isEndTimeUndefined = true;
      endTimestamp = null;
    } else if (isEndTimeUndefined) {
      endTimestamp =
          DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59)
              .millisecondsSinceEpoch;
    } else {
      endTimestamp = DateTime(endDate!.year, endDate!.month, endDate!.day,
              endTime!.hour, endTime!.minute)
          .millisecondsSinceEpoch;
    }

    if (startTimestamp != null &&
        endTimestamp != null &&
        startTimestamp! > endTimestamp!) {
      throw ArgumentError('End timestamp must be after start timestamp');
    }
  }
}

enum TargetType { atLeast, atMost }

class MeasurableTask {
  final String id;
  final String title;
  final String description;
  final String color;
  final num target;
  final TargetType targetType;
  final String unit;
  bool isCompleted;
  num howMuchHasBeenDone;

  MeasurableTask({
    String? id,
    required this.title,
    this.description = '',
    required this.color,
    required this.target,
    required this.targetType,
    required this.unit,
    this.isCompleted = false,
    this.howMuchHasBeenDone = 0,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4();

  void updateProgress(num value) {
    howMuchHasBeenDone = value;
    if (targetType == TargetType.atLeast) {
      isCompleted = target <= howMuchHasBeenDone;
    } else {
      isCompleted = target >= howMuchHasBeenDone;
    }
  }
}

class Subtask {
  bool isSubtaskCompleted;
  String title;

  Subtask({
    required this.isSubtaskCompleted,
    required this.title,
  });
}

class TaskWithSubtasks {
  String id;
  String title;
  String description;
  bool isCompleted;
  List<Subtask> subtasks;

  TaskWithSubtasks({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.subtasks,
  }): assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4();

  void updateCompletionStatus() {
    isCompleted = subtasks.every((subtask) => subtask.isSubtaskCompleted);
  }
}

/// The type definition for a JSON-serializable [Map].
typedef JsonMap = Map<String, dynamic>;
