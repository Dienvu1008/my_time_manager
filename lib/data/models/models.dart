import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'dart:convert';

//part 'models.g.dart';

// Model Task
@JsonSerializable()
class Task extends Equatable {
  final String id;
  final String taskListId;
  final String title;
  final bool isCompleted;
  final bool isImportant;
  final String description;
  final String location;
  final Color color;
  final List<String> tags;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;

  Task({
    String? id,
    required this.taskListId,
    required this.title,
    bool? isCompleted,
    bool? isImportant,
    String? description,
    String? location,
    Color? color,
    List<String>? tags,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false,
        isImportant = isImportant ?? false,
        description = description ?? '',
        location = location ?? '',
        color = color ?? Colors.white,
        tags = tags ?? [],
        dataFiles = dataFiles ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'description': description,
      'location': location,
      'color': color.value,
      'tags': jsonEncode(tags),
      'dataFiles': jsonEncode(dataFiles),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      taskListId: map['taskListId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      isImportant: map['isImportant'] == 1,
      description: map['description'],
      location: map['location'],
      color: Color(map['color']),
      tags: List<String>.from(jsonDecode(map['tags'])),
      dataFiles: List<String>.from(jsonDecode(map['dataFiles'])),
      updateTimeStamp: DateTime.parse(map['updateTimeStamp']),
    );
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

  @override
  List<Object?> get props => [id, taskListId, title, description, isCompleted];
}

//Model Task List
@JsonSerializable()
class TaskList extends Equatable {
  final String id;
  final String title;
  final String description;
  final Color color;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;

  TaskList({
    String? id,
    required this.title,
    String? description,
    Color? color,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        description = description ?? '',
        color = color ?? Colors.white,
        dataFiles = dataFiles ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color.value,
      'dataFiles': jsonEncode(dataFiles),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      color: Color(map['color']),
      dataFiles: List<String>.from(jsonDecode(map['dataFiles'])),
      updateTimeStamp: DateTime.parse(map['updateTimeStamp']),
    );
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

  TaskList.create(this.id, this.title, this.description, this.color,
      this.dataFiles, this.updateTimeStamp);

  TaskList.update(
      {required this.id,
      required this.title,
      required this.description,
      required this.color,
      required this.dataFiles,
      required this.updateTimeStamp});

  String toJson() => json.encode(toMap());

  factory TaskList.fromJson(String source) =>
      TaskList.fromMap(json.decode(source));

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() {
    return '''TaskList(
      id: $id, 
      title: $title, 
      description: $description)''';
  }

  @override
  List<Object?> get props => [id, title, description];
}

@JsonSerializable()
class TimeInterval extends Equatable {
  final String id;
  final String taskId;
  final String measuableTaskId;
  final String taskWithSubtasksId;
  final String location;
  final String notes;
  late final bool isCompleted;
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
  //just used for MeasuableTask
  double targetAtLeast;
  double targetAtMost;
  TargetType targetType;
  String unit;
  double howMuchHasBeenDone;
  //just used for task with sub tasks
  List<Subtask> subtasks;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;
  String? timeZone;

  TimeInterval(
      {String? id,
      required this.taskId,
      required this.measuableTaskId,
      required this.taskWithSubtasksId,
      bool? isCompleted,
      String? location,
      String? notes,
      this.startDate,
      this.endDate,
      this.startTime,
      this.endTime,
      this.isStartDateUndefined = false,
      this.isEndDateUndefined = false,
      this.isStartTimeUndefined = false,
      this.isEndTimeUndefined = false,
      double? targetAtLeast,
      double? targetAtMost,
      TargetType? targetType,
      String? unit,
      List<Subtask>? subtasks,
      double? howMuchHasBeenDone,
      List<String>? dataFiles,
      DateTime? updateTimeStamp,
      String? timeZone})
      : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false,
        location = location ?? '',
        notes = notes ?? '',
        targetAtLeast = targetAtLeast ?? double.negativeInfinity,
        targetAtMost = targetAtMost ?? double.infinity,
        unit = unit ?? '',
        subtasks = subtasks ?? [],
        targetType = targetType ?? TargetType.about,
        // isStartDateUndefined = isStartDateUndefined ?? false,
        // isEndDateUndefined = isEndDateUndefined ?? false,
        // isStartTimeUndefined = isStartTimeUndefined ?? false,
        // isEndTimeUndefined = isEndTimeUndefined ?? false,
        howMuchHasBeenDone = howMuchHasBeenDone ?? 0.0,
        dataFiles = dataFiles ?? [],
        timeZone = timeZone ?? '', //FlutterNativeTimezone.getLocalTimezone(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now() {
    Future<void> getTimeZone() async {
      timeZone = timeZone ?? await FlutterNativeTimezone.getLocalTimezone();
    }

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isCompleted': isCompleted ? 1 : 0,
      'taskId': taskId,
      'measuableTaskId': measuableTaskId,
      'taskWithSubtasksId': taskWithSubtasksId,

      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime':
          startTime != null ? startTime!.hour * 60 + startTime!.minute : null,
      'endTime': endTime != null ? endTime!.hour * 60 + endTime!.minute : null,
      'isStartDateUndefined': isStartDateUndefined ? 1 : 0,
      'isEndDateUndefined': isEndDateUndefined ? 1 : 0,
      'isStartTimeUndefined': isStartTimeUndefined ? 1 : 0,
      'isEndTimeUndefined': isEndTimeUndefined ? 1 : 0,

      'targetAtLeast': targetAtLeast, //REAL
      'targetAtMost': targetAtMost, //REAL
      'targetType': targetType.index,
      'unit': unit,
      'howMuchHasBeenDone': howMuchHasBeenDone,

      'subtasks':
          jsonEncode(subtasks.map((subtask) => subtask.toMap()).toList()),

      'dataFiles': jsonEncode(dataFiles),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
      'timeZone': timeZone,
    };
  }

  factory TimeInterval.fromMap(Map<String, dynamic> map) {
    return TimeInterval(
        id: map['id'],
        isCompleted: map['isCompleted'] == 1,
        taskId: map['taskId'],
        measuableTaskId: map['measuableTaskId'],
        taskWithSubtasksId: map['taskWithSubtasksId'],
        startDate:
            map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
        endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
        startTime: map['startTime'] != null
            ? TimeOfDay(
                hour: map['startTime'] ~/ 60,
                minute: map['startTime'] % 60,
              )
            : null,
        endTime: map['endTime'] != null
            ? TimeOfDay(hour: map['endTime'] ~/ 60, minute: map['endTime'] % 60)
            : null,
        isStartDateUndefined: map['isStartDateUndefined'] == 1,
        isEndDateUndefined: map['isEndDateUndefined'] == 1,
        isStartTimeUndefined: map['isStartTimeUndefined'] == 1,
        isEndTimeUndefined: map['isEndTimeUndefined'] == 1,
        targetAtLeast: map['targetAtLeast'],
        targetAtMost: map['targetAtMost'],
        // targetType: map['targetType'] == 0
        //     ? TargetType.about
        //     : map['targetType'] == 1
        //         ? TargetType.atLeast
        //         : TargetType.atMost,
        targetType: TargetType.values[map['targetType']],
        unit: map['unit'],
        howMuchHasBeenDone:
            (map['howMuchHasBeenDone'] as double?)?.toDouble() ??
                0.0, //(map['howMuchHasBeenDone'] as num).toDouble(),

        subtasks: List<Subtask>.from(jsonDecode(map['subtasks'])
            .map((subtaskMap) => Subtask.fromMap(subtaskMap))),
        dataFiles: List<String>.from(jsonDecode(map['dataFiles'])),
        updateTimeStamp: DateTime.parse(map['updateTimeStamp']),
        timeZone: map['timeZone']);
  }

  @override
  String toString() {
    return '''TimeInterval(
      id: $id, 
      taskId: $taskId,
      isCompleted: $isCompleted,
      startDate: $startDate,
      endDate: $endDate,
      startTime: $startTime,
      endTime: $endTime,
      isStartDateUndefined: $isStartDateUndefined,
      isEndDateUndefined: $isEndDateUndefined,
      isStartTimeUndefined: $isStartTimeUndefined,
      isEndTimeUndefined: $isEndTimeUndefined,
      howMuchHasBeenDone: $howMuchHasBeenDone,
      )''';
  }

  @override
  List<Object?> get props => [id];
}

enum TargetType { atLeast, atMost, about }

class MeasurableTask {
  final String id;
  final String taskListId;
  final String title;
  final String description;
  final String location;
  final Color color;
  final double targetAtLeast;
  final double targetAtMost;
  final TargetType targetType;
  final String unit;
  bool isCompleted;
  bool isImportant;
  double howMuchHasBeenDone;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;

  MeasurableTask({
    String? id,
    required this.taskListId,
    required this.title,
    String? description,
    String? location,
    Color? color,
    required this.targetAtLeast,
    required this.targetAtMost,
    required this.targetType,
    required this.unit,
    bool? isCompleted,
    bool? isImportant,
    double? howMuchHasBeenDone,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false,
        isImportant = isImportant ?? false,
        description = description ?? '',
        location = location ?? '',
        color = color ?? Colors.white,
        howMuchHasBeenDone = howMuchHasBeenDone ?? 0.0,
        dataFiles = dataFiles ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  // void updateProgress(num value) {
  //   howMuchHasBeenDone = value;
  //   if (targetType == TargetType.atLeast) {
  //     isCompleted = target <= howMuchHasBeenDone;
  //   } else {
  //     isCompleted = target >= howMuchHasBeenDone;
  //   }
  // }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'description': description,
      'location': location,
      'color': color.value,
      'targetAtLeast': targetAtLeast, //REAL
      'targetAtMost': targetAtMost, //REAL
      'targetType': targetType.index,
      'unit': unit,
      'isCompleted': isCompleted ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'howMuchHasBeenDone': howMuchHasBeenDone, //REAL
      'dataFiles': jsonEncode(dataFiles),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory MeasurableTask.fromMap(Map<String, dynamic> map) {
    return MeasurableTask(
        id: map['id'],
        taskListId: map['taskListId'],
        title: map['title'],
        description: map['description'],
        location: map['location'],
        color: Color(map['color']),
        targetAtLeast: map['targetAtLeast'],
        targetAtMost: map['targetAtMost'],
        // targetType: map['targetType'] == 0
        //     ? TargetType.about
        //     : map['targetType'] == 1
        //         ? TargetType.atLeast
        //         : TargetType.atMost,
        targetType: TargetType.values[map['targetType']],
        unit: map['unit'],
        isCompleted: map['isCompleted'] == 1,
        isImportant: map['isImportant'] == 1,
        howMuchHasBeenDone:
            (map['howMuchHasBeenDone'] as num?)?.toDouble() ?? 0.0,
        dataFiles: map['dataFiles'] != null
            ? List<String>.from(jsonDecode(map['dataFiles']))
            : [],
        updateTimeStamp: map['updateTimeStamp'] != null
            ? DateTime.parse(map['updateTimeStamp'])
            : null);
  }
}

class Subtask {
  bool isSubtaskCompleted;
  String title;

  Subtask({
    required this.isSubtaskCompleted,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'isSubtaskCompleted': isSubtaskCompleted ? 1 : 0,
      'title': title,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      isSubtaskCompleted: map['isSubtaskCompleted'] == 1,
      title: map['title'],
    );
  }
}

class TaskWithSubtasks {
  String id;
  final String taskListId;
  final String title;
  final String description;
  final String location;
  final Color color;
  bool isCompleted;
  bool isImportant;
  List<Subtask> subtasks;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;

  TaskWithSubtasks({
    String? id,
    required this.taskListId,
    required this.title,
    String? description,
    String? location,
    Color? color,
    bool? isCompleted,
    bool? isImportant,
    required this.subtasks,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        description = description ?? '',
        location = location ?? '',
        color = color ?? Colors.white,
        isCompleted = isCompleted ?? false,
        isImportant = isImportant ?? false,
        dataFiles = dataFiles ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  void updateCompletionStatus() {
    isCompleted = subtasks.every((subtask) => subtask.isSubtaskCompleted);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'description': description,
      'location': location,
      'color': color.value,
      'isCompleted': isCompleted ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'subtasks':
          jsonEncode(subtasks.map((subtask) => subtask.toMap()).toList()),
      'dataFiles': jsonEncode(dataFiles),
      'updateTimeStamp': updateTimeStamp
          .toIso8601String() //updateTimeStamp.millisecondsSinceEpoch,
    };
  }

  factory TaskWithSubtasks.fromMap(Map<String, dynamic> map) {
    return TaskWithSubtasks(
        id: map['id'],
        taskListId: map['taskListId'],
        title: map['title'],
        description: map['description'],
        location: map['location'],
        color: Color(map['color']),
        isCompleted: map['isCompleted'] == 1,
        isImportant: map['isImportant'] == 1,
        subtasks: List<Subtask>.from(jsonDecode(map['subtasks'])
            .map((subtaskMap) => Subtask.fromMap(subtaskMap))),
        dataFiles: List<String>.from(jsonDecode(map['dataFiles'])),
        updateTimeStamp: map['updateTimeStamp'] != null
            ? DateTime.parse(map['updateTimeStamp'])
            : null
        //DateTime.fromMillisecondsSinceEpoch(map['updateTimeStamp']),
        );
  }
}

class Event extends Equatable {
  final String id;
  final String taskListId;
  final String title;
  final String description;
  final String location;
  final Color color;
  final DateTime startTimeStamp;
  final DateTime endTimeStamp;
  final List<String> tags;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;

  Event({
    String? id,
    required this.taskListId,
    required this.title,
    String? description,
    String? location,
    Color? color,
    required this.startTimeStamp,
    required this.endTimeStamp,
    List<String>? tags,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        description = description ?? '',
        location = location ?? '',
        color = color ?? Colors.white,
        tags = tags ?? [],
        dataFiles = dataFiles ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'description': description,
      'location': location,
      'color': color.value,
      'startTimeStamp': startTimeStamp.millisecondsSinceEpoch, // INTEGER
      'endTimeStamp': endTimeStamp.millisecondsSinceEpoch, // INTEGER
      'tags': jsonEncode(tags),
      'dataFiles': jsonEncode(dataFiles),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      taskListId: map['taskListId'],
      title: map['title'],
      description: map['description'],
      location: map['location'],
      color: Color(map['color']),
      startTimeStamp:
          DateTime.fromMillisecondsSinceEpoch(map['startTimeStamp']),
      endTimeStamp: DateTime.fromMillisecondsSinceEpoch(map['endTimeStamp']),
      tags: List<String>.from(jsonDecode(map['tags'])),
      dataFiles: List<String>.from(jsonDecode(map['dataFiles'])),
      updateTimeStamp: DateTime.parse(map['updateTimeStamp']),
    );
  }

  String toJson() => json.encode(toMap());
  factory Event.fromJson(String source) => Event.fromMap(json.decode(source));
  // Implement toString to make it easier to see information about
  // each task when using the print statement.

  @override
  String toString() {
    return '''Task(
      id: $id, 
      title: $title, 
      description: $description, 
      color: $color, 
      taskListId: $taskListId)''';
  }

  @override
  List<Object?> get props => [id, taskListId, title, description];
}

class FocusInterval {
  final DateTime startTimeStamp;
  final DateTime endTimeStamp;

  FocusInterval({required this.startTimeStamp, required this.endTimeStamp});

  Map<String, dynamic> toMap() {
    return {
      'startTimeStamp': startTimeStamp.millisecondsSinceEpoch, // INTEGER
      'endTimeStamp': endTimeStamp.millisecondsSinceEpoch, // INTEGER
    };
  }

  factory FocusInterval.fromMap(Map<String, dynamic> map) {
    return FocusInterval(
      startTimeStamp:
          DateTime.fromMillisecondsSinceEpoch(map['startTimeStamp']),
      endTimeStamp: DateTime.fromMillisecondsSinceEpoch(map['endTimeStamp']),
    );
  }
}

class FocusIntervalsStats {
  String? id;
  String? taskId;
  String? measurableTaskId;
  String? taskWithSubtasksId;
  List<FocusInterval> focusIntervals;

  FocusIntervalsStats({
    String? id,
    String? taskId,
    String? measurableTaskId,
    String? taskWithSubtasksId,
    List<FocusInterval>? focusIntervals,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        taskId = taskId ?? '',
        taskWithSubtasksId = taskWithSubtasksId ?? '',
        measurableTaskId = measurableTaskId ?? '',
        focusIntervals = focusIntervals ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'taskWithSubtasksId': taskWithSubtasksId,
      'measurableTaskId': measurableTaskId,
      'focusIntervals': jsonEncode(focusIntervals!
          .map((focusInterval) => focusInterval.toMap())
          .toList()),
    };
  }

  factory FocusIntervalsStats.fromMap(Map<String, dynamic> map) {
    return FocusIntervalsStats(
        id: map['id'],
        taskId: map['taskId'],
        taskWithSubtasksId: map['taskWithSubtasksId'],
        measurableTaskId: map['measurableTaskId'],
        focusIntervals: List<FocusInterval>.from(
            jsonDecode(map['focusIntervals']).map((focusIntervalMap) =>
                FocusInterval.fromMap(focusIntervalMap))));
  }
}

/// The type definition for a JSON-serializable [Map].
typedef JsonMap = Map<String, dynamic>;
