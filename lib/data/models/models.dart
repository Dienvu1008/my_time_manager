import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';

//part 'models.g.dart';

// Model Task
@JsonSerializable()
class Task extends Equatable {
  //Khi tạo bảng, database sẽ cố gắng truy cập các thuộc tính của lớp Task thông qua truy cập tĩnh.
  //Tuy nhiên, id, tittle, description... là các thuộc tính của thể hiện (instance) và không phải là một thuộc tính tĩnh (static) của lớp Task.
  //Để khắc phục điều này, ta thêm các thuộc tính tĩnh mới trong lớp Task
  // static final tableTasks = "Tasks";
  // static final dbId = 'id';
  // static final dbTitle = 'title';
  // static final dbDescription = 'description';
  // static final dbIsCompleted = 'isCompleted';
  // static final dbTaskListId = 'taskListId';

  final String id;
  final String title;
  final String description;
  final Color color;
  final bool isCompleted;
  final String taskListId;

  Task({
    required this.title,
    required this.taskListId,
    String? id,
    this.description = '',
    //Color? color = ,
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
      'isCompleted': isCompleted,
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
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'],
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
  TaskList({required this.title, String? id})
      : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
    };
  }

  TaskList copyWith({
    String? id,
    String? title,
  }) {
    return TaskList(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }

  //static TaskList fromJson(JsonMap json) => _$TaskListFromJson(json);

  //JsonMap toJson() => _$TaskListToJson(this);

  TaskList.create(this.id, this.title);

  TaskList.update({required this.id, required this.title}) {}

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'],
      title: map['title'],
    );
  }
  // : this.update(
  //     id: map[dbId],
  //     title: map[dbTitle],
  //   );
  String toJson() => json.encode(toMap());

  factory TaskList.fromJson(String source) => TaskList.fromMap(json.decode(source));

  // Implement toString to make it easier to see information about
  // each breed when using the print statement.
  @override
  String toString() => 'TaskList(id: $id, title: $title)';

  @override
  List<Object?> get props => [id, title];
}

/// The type definition for a JSON-serializable [Map].
typedef JsonMap = Map<String, dynamic>;
