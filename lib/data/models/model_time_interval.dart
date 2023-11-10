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
  bool isCompleted;
  bool isImportant;
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
  bool? isGone;
  bool? isToday;
  bool? isTomorrow;
  bool? isYesterday;
  bool? isThisWeek;
  bool? isThisMonth;
  bool? isNextMonth;
  bool? isInProgress;
  bool isDetailsAdded;
  bool isDescriptionChanged;
  bool isLocationChanged;
  bool isSubtasksChanged;
  bool isTargetChanged;

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
    bool? isImportant,
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
    this.isDetailsAdded = false,
    this.isDescriptionChanged = false,
    this.isLocationChanged = false,
    this.isTargetChanged = false,
    this.isSubtasksChanged = false,
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
        isImportant = isImportant ?? false,
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
      //isStartDateUndefined == true;
      isStartTimeUndefined = true;
      startDate = null;
      startTime = null;
      startTimestamp = null;
    } else {
      if (startDate == null) {
        //isStartDateUndefined == false;
        //startDate == null;
        //isStartTimeUndefined == true;
        //throw ArgumentError(
        //'If the start date is determined, the start date must be set');
      } else {
        if (isStartTimeUndefined) {
          //isStartDateUndefined == false;
          //startDate != null;
          //isStartTimeUndefined == true;
          startTime = null;
          startTimestamp =
              DateTime(startDate!.year, startDate!.month, startDate!.day)
                  .millisecondsSinceEpoch;
        } else {
          if (startTime == null) {
            //isStartDateUndefined == false;
            //startDate != null;
            //isStartTimeUndefined == false;
            //startTime == null;
            //throw ArgumentError(
            //'If the start time is determined, the start time must be set');
          } else {
            //isStartDateUndefined == false;
            //startDate != null;
            //isStartTimeUndefined == false;
            //startTime != null;
            startTimestamp = DateTime(startDate!.year, startDate!.month,
                    startDate!.day, startTime!.hour, startTime!.minute)
                .millisecondsSinceEpoch;
          }
        }
      }
    }

    if (isEndDateUndefined) {
      //isEndDateUndefined == true;
      isEndTimeUndefined = true;
      endDate = null;
      endTime = null;
      endTimestamp = null;
    } else {
      if (endDate == null) {
        //isEndDateUndefined == false;
        //endDate == null;
        //isEndTimeUndefined == true;
        //throw ArgumentError(
        //'If the end date is determined, the end date must be set');
      } else {
        if (isEndTimeUndefined) {
          //isEndDateUndefined == false;
          //endDate != null;
          //isEndTimeUndefined == true;
          endTime = null;
          endTimestamp =
              DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59)
                  .millisecondsSinceEpoch;
        } else {
          if (endTime == null) {
            //isEndDateUndefined == false;
            //endDate != null;
            //isEndTimeUndefined == false;
            //endTime == null;
            //throw ArgumentError(
            //'If the end time is determined, the end time must be set');
          } else {
            //isEndDateUndefined == false;
            //endDate != null;
            //isEndTimeUndefined == false;
            //endTime != null;
            endTimestamp = DateTime(endDate!.year, endDate!.month, endDate!.day,
                    endTime!.hour, endTime!.minute)
                .millisecondsSinceEpoch;
          }
        }
      }
    }

    // if (endDate != null && endDate!.isBefore(DateTime.now())) {
    //   isGone = true;
    // } else {
    //   isGone = false;
    // }

    if (endTimestamp != null &&
        endTimestamp! < DateTime.now().millisecondsSinceEpoch) {
      isGone = true;
    } else {
      isGone = false;
    }

    if ((startDate != null &&
            startDate!.day == DateTime.now().day &&
            startDate!.month == DateTime.now().month &&
            startDate!.year == DateTime.now().year) ||
        (endDate != null &&
            endDate!.day == DateTime.now().day &&
            endDate!.month == DateTime.now().month &&
            endDate!.year == DateTime.now().year)) {
      isToday = true;
    }

    if (startTimestamp != null && endTimestamp != null) {
      if (startTimestamp! < DateTime.now().millisecondsSinceEpoch &&
          endTimestamp! > DateTime.now().millisecondsSinceEpoch) {
        isInProgress = true;
      } else {
        isInProgress = false;
      }
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 7));
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth =
        DateTime(now.year, now.month + 1).subtract(Duration(days: 1));
    final startOfNextMonth = DateTime(now.year, now.month + 1);
    final endOfNextMonth =
        DateTime(now.year, now.month + 2).subtract(Duration(days: 1));

    if (startDate != null) {
      isThisWeek =
          startDate!.isAfter(startOfWeek) && startDate!.isBefore(endOfWeek);
    } else if (endDate != null) {
      isThisWeek =
          endDate!.isAfter(startOfWeek) && endDate!.isBefore(endOfWeek);
    } else {
      isThisWeek = false;
    }

    if (startDate != null) {
      isThisMonth =
          startDate!.isAfter(startOfMonth) && startDate!.isBefore(endOfMonth);
    } else if (endDate != null) {
      isThisMonth =
          endDate!.isAfter(startOfMonth) && endDate!.isBefore(endOfMonth);
    } else {
      isThisMonth = false;
    }

    if (startDate != null) {
      isNextMonth = startDate!.isAfter(startOfNextMonth) &&
          startDate!.isBefore(endOfNextMonth);
    } else if (endDate != null) {
      isNextMonth = endDate!.isAfter(startOfNextMonth) &&
          endDate!.isBefore(endOfNextMonth);
    } else {
      isNextMonth = false;
    }

    if (startTimestamp != null &&
        endTimestamp != null &&
        startTimestamp! > endTimestamp!) {
      //throw ArgumentError('End timestamp must be after start timestamp');
    }
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isCompleted': isCompleted ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
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
        isImportant: map['isImportant'] == 1,
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

  TimeInterval copyWith(
      {String? id,
      String? taskId,
      String? measurableTaskId,
      String? taskWithSubtasksId,
      bool? isCompleted,
      bool? isImportant,
      String? location,
      String? description,
      DateTime? startDate,
      DateTime? endDate,
      TimeOfDay? startTime,
      TimeOfDay? endTime,
      bool? isStartDateUndefined,
      bool? isEndDateUndefined,
      bool? isStartTimeUndefined,
      bool? isEndTimeUndefined,
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
      String? title}) {
    return TimeInterval(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        measurableTaskId: measurableTaskId ?? this.measurableTaskId,
        taskWithSubtasksId: taskWithSubtasksId ?? this.taskWithSubtasksId,
        isCompleted: isCompleted ?? this.isCompleted,
        isImportant: isImportant ?? this.isImportant,
        location: location ?? this.location,
        description: description ?? this.description,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isStartDateUndefined: isStartDateUndefined ?? this.isStartDateUndefined,
        isEndDateUndefined: isEndDateUndefined ?? this.isEndDateUndefined,
        isStartTimeUndefined: isStartTimeUndefined ?? this.isStartTimeUndefined,
        isEndTimeUndefined: isEndTimeUndefined ?? this.isEndTimeUndefined,
        targetAtLeast: targetAtLeast ?? this.targetAtLeast,
        targetAtMost: targetAtMost ?? this.targetAtMost,
        targetType: targetType ?? this.targetType,
        unit: unit ?? this.unit,
        subtasks: subtasks ?? this.subtasks,
        howMuchHasBeenDone: howMuchHasBeenDone ?? this.howMuchHasBeenDone,
        dataFiles: dataFiles ?? this.dataFiles,
        updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
        timeZone: timeZone ?? this.timeZone,
        color: color ?? this.color,
        title: title ?? this.title);
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
