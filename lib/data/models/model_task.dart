// Model Task
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

@JsonSerializable()
class Task extends Equatable {
  String id;
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
