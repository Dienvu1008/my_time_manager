//Model Task List
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

@JsonSerializable()
class TaskList extends Equatable {
  final String id;
  final String title;
  final String description;

  /// JSON document appflowy_editor cho mô tả có định dạng (rỗng = chưa có).
  final String descriptionDoc;
  final Color color;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;

  TaskList({
    String? id,
    required this.title,
    String? description,
    String? descriptionDoc,
    Color? color,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  })  : //assert(
          //id == null || id.isEmpty,
          //'id can not be null and should not be empty',
        //),
        id = id ?? const Uuid().v4(),
        description = description ?? '',
        descriptionDoc = descriptionDoc ?? '',
        color = color ?? Colors.white,
        dataFiles = dataFiles ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'descriptionDoc': descriptionDoc,
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
      descriptionDoc: map['descriptionDoc'] as String?,
      color: Color(map['color']),
      dataFiles: List<String>.from(jsonDecode(map['dataFiles'])),
      updateTimeStamp: DateTime.parse(map['updateTimeStamp']),
    );
  }

  TaskList copyWith({
    String? id,
    String? title,
    String? description,
    String? descriptionDoc,
  }) {
    return TaskList(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        descriptionDoc: descriptionDoc ?? this.descriptionDoc);
  }

  //static TaskList fromJson(JsonMap json) => _$TaskListFromJson(json);

  //JsonMap toJson() => _$TaskListToJson(this);

  TaskList.create(this.id, this.title, this.description, this.color,
      this.dataFiles, this.updateTimeStamp)
      : descriptionDoc = '';

  TaskList.update(
      {required this.id,
      required this.title,
      required this.description,
      required this.color,
      required this.dataFiles,
      required this.updateTimeStamp})
      : descriptionDoc = '';

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
