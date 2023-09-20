import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:uuid/uuid.dart';

import 'model_measurable_task.dart';

@JsonSerializable()
class TimeInterval {
  String id;
  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;
  final String location;
  final String description;
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
  Color color;
  String title;

  TimeInterval({
    String? id,
    this.taskId,
    this.measurableTaskId,
    this.taskWithSubtasksId,
    bool? isCompleted,
    String? location,
    String? description,
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
    String? timeZone,
    Color? color,
    String? title, 
    //int? startTimestamp,
    //int? endTimestamp
  })  : //assert(
          //id == null || id.isNotEmpty,
          //'id can not be null and should be empty',
        //),
        //taskId = taskId,
        //measurableTaskId = measurableTaskId,
        //taskWithSubtasksId = taskWithSubtasksId,
        id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false,
        color = color ?? const Color(0xff000000),
        title = title ?? '', 
        location = location ?? '',
        description = description ?? '',
        targetAtLeast = targetAtLeast ?? double.negativeInfinity,
        targetAtMost = targetAtMost ?? double.infinity,
        unit = unit ?? '',
        subtasks = subtasks ?? [],
        targetType = targetType ?? TargetType.about,
        //color = color ?? Color()._getColor,
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
    } else if (isStartTimeUndefined && startDate != null) {
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

    // if (startTimestamp != null &&
    //     endTimestamp != null &&
    //     startTimestamp! > endTimestamp!) {
    //   throw ArgumentError('End timestamp must be after start timestamp');
    // }

    //init();
  }

  // Future<Color> getColor() async {
  //   final DatabaseManager databaseManager = DatabaseManager();
  //   if (taskId != null) {
  //     final task = await databaseManager.task(taskId!);
  //     return task.color;
  //   } else if (measuableTaskId != null) {
  //     final measurableTask =
  //         await databaseManager.measurableTask(measuableTaskId!);
  //     return measurableTask.color;
  //   } else if (taskWithSubtasksId != null) {
  //     final taskWithSubtasks =
  //         await databaseManager.taskWithSubtasks(taskWithSubtasksId!);
  //     return taskWithSubtasks.color;
  //   }
  //   // Trả về màu mặc định nếu không có id nào được chỉ định
  //   return Colors.black;
  // }

  // Future<String> getTitle() async {
  //   final DatabaseManager databaseManager = DatabaseManager();
  //   if (taskId != null) {
  //     final task = await databaseManager.task(taskId!);
  //     return task.title;
  //   } else if (measuableTaskId != null) {
  //     final measurableTask =
  //         await databaseManager.measurableTask(measuableTaskId!);
  //     return measurableTask.title;
  //   } else if (taskWithSubtasksId != null) {
  //     final taskWithSubtasks =
  //         await databaseManager.taskWithSubtasks(taskWithSubtasksId!);
  //     return taskWithSubtasks.title;
  //   }
  //   return '';
  // }

  // Future<void> init() async {
  //   title = await getTitle();
  //   color = await getColor();
  // }

  

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isCompleted': isCompleted ? 1 : 0,
      'taskId': taskId,
      'measurableTaskId': measurableTaskId,
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
      'color': color.value,
      'title': title,
      'location': location,
      'description': description,
    };
    
  }

  factory TimeInterval.fromMap(Map<String, dynamic> map) {
    return TimeInterval(
        id: map['id'],
        isCompleted: map['isCompleted'] == 1,
        taskId: map['taskId'],
        measurableTaskId: map['measurableTaskId'],
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
        color: Color(map['color']),
        title: map['title'],
        location: map['location'],
        description: map['description'],
        timeZone: map['timeZone']);
        
  }

  // @override
  // String toString() {
  //   return '''TimeInterval(
  //     id: $id,
  //     taskId: $taskId,
  //     isCompleted: $isCompleted,
  //     startDate: $startDate,
  //     endDate: $endDate,
  //     startTime: $startTime,
  //     endTime: $endTime,
  //     isStartDateUndefined: $isStartDateUndefined,
  //     isEndDateUndefined: $isEndDateUndefined,
  //     isStartTimeUndefined: $isStartTimeUndefined,
  //     isEndTimeUndefined: $isEndTimeUndefined,
  //     howMuchHasBeenDone: $howMuchHasBeenDone,
  //     )''';
  // }

  // @override
  // List<Object?> get props => [id];
}
