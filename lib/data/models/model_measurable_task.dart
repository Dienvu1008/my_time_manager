import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum TargetType { atLeast, atMost, about }

class MeasurableTask {
  String id;
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
  })  : //assert(
        //   id == null || id.isNotEmpty,
        //   'id can not be null and should be empty',
        // ),
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

  MeasurableTask copyWith({
    String? id,
    String? taskListId,
    String? title,
    String? description,
    String? location,
    Color? color,
    double? targetAtLeast,
    double? targetAtMost,
    TargetType? targetType,
    String? unit,
    bool? isCompleted,
    bool? isImportant,
    double? howMuchHasBeenDone,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  }) {
    return MeasurableTask(
      id: id ?? this.id,
      taskListId: taskListId ?? this.taskListId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      color: color ?? this.color,
      targetAtLeast: targetAtLeast ?? this.targetAtLeast,
      targetAtMost: targetAtMost ?? this.targetAtMost,
      targetType: targetType ?? this.targetType,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      howMuchHasBeenDone: howMuchHasBeenDone ?? this.howMuchHasBeenDone,
      dataFiles: dataFiles ?? this.dataFiles,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
    );
  }
}
