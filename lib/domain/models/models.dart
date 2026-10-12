import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';


//part 'models.g.dart';

class Event extends Equatable {
  String id;
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

