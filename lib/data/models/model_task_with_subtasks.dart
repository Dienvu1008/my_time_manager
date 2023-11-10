import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
  })  : //assert(
        //   id == null || id.isNotEmpty,
        //   'id can not be null and should be empty',
        // ),
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

  TaskWithSubtasks copyWith({
    String? id,
    String? taskListId,
    String? title,
    String? description,
    String? location,
    Color? color,
    bool? isCompleted,
    bool? isImportant,
    List<Subtask>? subtasks,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  }) {
    return TaskWithSubtasks(
      id: id ?? this.id,
      taskListId: taskListId ?? this.taskListId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      subtasks: subtasks ?? this.subtasks,
      dataFiles: dataFiles ?? this.dataFiles,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
    );
  }
}
