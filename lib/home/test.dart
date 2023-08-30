// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// // void main() {

// //     sqfliteFfiInit();
// //     databaseFactory = databaseFactoryFfi;

// //   runApp(MyApp());
// // }

// class TaskList {
//   final int id;
//   final String title;
//   final String description;

//   TaskList({required this.id, required this.title, required this.description});

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'description': description,
//     };
//   }
// }

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   List<TaskList> _taskLists = [];
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   late Database _database;

//   @override
//   void initState() {
//     super.initState();
//     _loadTaskLists();
//   }

//   Future<void> _loadTaskLists() async {
//     // Load task lists from sqflite database
//     // Replace with your own code to load task lists from sqflite database
//     //     _database = await openDatabase(
//     //   join(await getDatabasesPath(), 'strings.db'),
//     //   onCreate: (db, version) {
//     //     return db.execute(
//     //       "CREATE TABLE strings(id INTEGER PRIMARY KEY, string TEXT)",
//     //     );
//     //   },
//     //   version: 1,
//     // );

//     final Database db = await openDatabase('my_db.db');
//     final List<Map<String, dynamic>> maps = await db.query('task_lists');
//     setState(() {
//       _taskLists = List.generate(maps.length, (i) {
//         return TaskList(
//           id: maps[i]['id'],
//           title: maps[i]['title'],
//           description: maps[i]['description'],
//         );
//       });
//     });

//     // Load task list order from shared preferences
//     final prefs = await SharedPreferences.getInstance();
//     final order = prefs.getStringList('order');
//     if (order != null) {
//       setState(() {
//         _taskLists.sort((a, b) => order.indexOf(a.id.toString()).compareTo(order.indexOf(b.id.toString())));
//       });
//     }
//   }

//   Future<void> _saveTaskListOrder() async {
//     // Save task list order to shared preferences
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setStringList('order', _taskLists.map((e) => e.id.toString()).toList());
//   }

//   Future<void> _addTaskList(TaskList taskList) async {
//     // Add new task list to sqflite database
//     // Replace with your own code to add new task list to sqflite database
//     final Database db = await openDatabase('my_db.db');
//     await db.insert(
//       'task_lists',
//       taskList.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );

//     setState(() {
//       _taskLists.insert(0, taskList);
//     });
//     await _saveTaskListOrder();
//   }

//   Future<void> _deleteTaskList(TaskList taskList) async {
//     // Delete task list from sqflite database
//     // Replace with your own code to delete task list from sqflite database
//     final Database db = await openDatabase('my_db.db');
//     await db.delete(
//       'task_lists',
//       where: "id = ?",
//       whereArgs: [taskList.id],
//     );

//     setState(() {
//       _taskLists.remove(taskList);
//     });
//     await _saveTaskListOrder();
//   }

//   Future<void> _updateTaskList(TaskList oldTaskList, TaskList newTaskList) async {
//     // Update task list in sqflite database
//     // Replace with your own code to update task list in sqflite database
//     final Database db = await openDatabase('my_db.db');
//     await db.update(
//       'task_lists',
//       newTaskList.toMap(),
//       where: "id = ?",
//       whereArgs: [oldTaskList.id],
//     );

//     setState(() {
//       int index = _taskLists.indexOf(oldTaskList);
//       if (index != -1) {
//         _taskLists[index] = newTaskList;
//       }
//     });
//   }

//   void _showAddTaskDialog(BuildContext context) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text('Add Task'),
//             content: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: <Widget>[
//                   TextFormField(
//                     controller: _titleController,
//                     decoration: InputDecoration(labelText: 'Title'),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a title';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField(
//                     controller: _descriptionController,
//                     decoration: InputDecoration(labelText: 'Description'),
//                   ),
//                 ],
//               ),
//             ),
//             actions: <Widget>[
//               TextButton(
//                 child: Text('Cancel'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//               TextButton(
//                 child: Text('Add'),
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     // Add new task list
//                     await _addTaskList(TaskList(
//                       id: DateTime.now().millisecondsSinceEpoch,
//                       title: _titleController.text,
//                       description: _descriptionController.text,
//                     ));
//                     // Clear text fields
//                     _titleController.clear();
//                     _descriptionController.clear();
//                     Navigator.of(context).pop();
//                   }
//                 },
//               ),
//             ],
//           );
//         });
//   }

//   void _showEditTaskDialog(BuildContext context, TaskList taskList) {
//     _titleController.text = taskList.title;
//     _descriptionController.text = taskList.description;
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text('Edit Task'),
//             content: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: <Widget>[
//                   TextFormField(
//                     controller: _titleController,
//                     decoration: InputDecoration(labelText: 'Title'),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a title';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField(
//                     controller:_descriptionController,
//                     decoration: InputDecoration(labelText:'Description'),
//                   ),
//                 ],
//               ),
//             ),
//             actions:<Widget>[
//               TextButton(
//                 child: Text('Cancel'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//               TextButton(
//                 child: Text('Save'),
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     // Update task list
//                     await _updateTaskList(taskList, TaskList(id : taskList.id, title :_titleController.text, description :_descriptionController.text));
//                     // Clear text fields
//                     _titleController.clear();
//                     _descriptionController.clear();
//                     Navigator.of(context).pop();
//                   }
//                 },
//               ),
//             ],
//           );
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home:Scaffold(
//         appBar : AppBar(title : Text('Task List')),
//         body : ReorderableListView.builder(
//           itemCount :_taskLists.length,
//           itemBuilder :(BuildContext context, int index){
//             final taskList =_taskLists[index];
//             return Dismissible(key : ValueKey(taskList.id),
//               background : Container(color : Colors.red),
//               onDismissed :(direction){
//                 // Delete task list
//                 _deleteTaskList(taskList);
//               },
//               child : ListTile(title : Text(taskList.title),
//                 subtitle :Text(taskList.description),
//                 onTap :(){
//                   // Show edit task dialog
//                   _showEditTaskDialog(context, taskList);
//                 },
//               ),
//             );
//           },
//           onReorder :(int oldIndex, int newIndex){
//             setState((){
//               if (newIndex > oldIndex) {
//                 newIndex -= 1;
//               }
//               final TaskList item =_taskLists.removeAt(oldIndex);
//               _taskLists.insert(newIndex, item);
//             });
//             _saveTaskListOrder();
//           },
//         ),
//         floatingActionButton : FloatingActionButton(child : Icon(Icons.add),
//           onPressed :(){
//             // Show add task dialog
//             _showAddTaskDialog(context);
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/home/timeintervaltest.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/models.dart';

class TaskWithSubtasksBloc
    extends Bloc<TaskWithSubtasksEvent, TaskWithSubtasksState> {
  final TaskWithSubtasks taskWithSubtasks;
  late SharedPreferences _prefs;

  TaskWithSubtasksBloc(this.taskWithSubtasks)
      : super(TaskWithSubtasksInitial()) {
    on<InitTaskWithSubtasks>((event, emit) async {
      _prefs = await SharedPreferences.getInstance();
      final isExpanded =
          _prefs.getBool('isExpanded_${taskWithSubtasks.id}') ?? true;
      emit(TaskWithSubtasksLoaded(isExpanded));
    });

    on<SaveIsExpanded>((event, emit) async {
      _prefs.setBool('isExpanded_${taskWithSubtasks.id}', event.isExpanded);
    });
  }
}

abstract class TaskWithSubtasksEvent {}

class InitTaskWithSubtasks extends TaskWithSubtasksEvent {}

class SaveIsExpanded extends TaskWithSubtasksEvent {
  final bool isExpanded;

  SaveIsExpanded(this.isExpanded);
}

abstract class TaskWithSubtasksState {}

class TaskWithSubtasksInitial extends TaskWithSubtasksState {}

class TaskWithSubtasksLoaded extends TaskWithSubtasksState {
  final bool isExpanded;

  TaskWithSubtasksLoaded(this.isExpanded);
}

class BlocTaskWithSubtasksCard extends StatelessWidget {
  final TaskWithSubtasks taskWithSubtasks;
  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;

  const BlocTaskWithSubtasksCard({
    Key? key,
    required this.taskWithSubtasks,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
  }) : super(key: key);

  static Color contrastColor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    switch (brightness) {
      case Brightness.dark:
        return Colors.white;
      case Brightness.light:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskWithSubtasksColor = taskWithSubtasks.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: taskWithSubtasksColor)
        : ColorScheme.light(primary: taskWithSubtasksColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);

    return BlocProvider(
      create: (context) =>
          TaskWithSubtasksBloc(taskWithSubtasks)..add(InitTaskWithSubtasks()),
      child: BlocBuilder<TaskWithSubtasksBloc, TaskWithSubtasksState>(
        builder: (context, state) {
          if (state is TaskWithSubtasksInitial) {
            return const CircularProgressIndicator();
          } else if (state is TaskWithSubtasksLoaded) {
            return Card(
              color: backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onTaskWithSubtasksEdit(taskWithSubtasks),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              taskWithSubtasks.title,
                              style: TextStyle(
                                color: labelColor,
                                decoration: taskWithSubtasks.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: taskWithSubtasks.description.isNotEmpty
                                ? Text(
                                    taskWithSubtasks.description,
                                    style: TextStyle(color: labelColor),
                                  )
                                : null,
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_outlined,
                                  color: labelColor),
                              onSelected: (String result) {
                                if (result == 'option1') {
                                  onTaskWithSubtasksEdit(taskWithSubtasks);
                                } else if (result == 'option2') {
                                  onTaskWithSubtasksDelete(taskWithSubtasks);
                                } else if (result == 'option3') {
                                  onTaskWithSubtasksToggleComplete(
                                      taskWithSubtasks);
                                } else if (result == 'option4') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => TimeIntervalPage(
                                            taskWithSubtasks:
                                                taskWithSubtasks)),
                                  );
                                } else if (result == 'option5') {
                                  final isExpanded = !state.isExpanded;
                                  context
                                      .read<TaskWithSubtasksBloc>()
                                      .add(SaveIsExpanded(isExpanded));
                                  context
                                      .read<TaskWithSubtasksBloc>()
                                      .add(InitTaskWithSubtasks());
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'option5',
                                  child: Row(
                                    children: [
                                      Icon(state.isExpanded
                                          ? Icons.chevron_right
                                          : Icons.expand_more),
                                      const SizedBox(width: 8),
                                      state.isExpanded
                                          ? const Text('Hide sub-tasks')
                                          : const Text('Show sub-tasks'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'option3',
                                  child: Row(
                                    children: [
                                      Icon(taskWithSubtasks.isCompleted
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank),
                                      const SizedBox(width: 8),
                                      taskWithSubtasks.isCompleted
                                          ? const Text('Mark as incompleted')
                                          : const Text('Mark as completed'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'option4',
                                  child: Row(
                                    children: [
                                      Icon(Icons.hourglass_empty),
                                      SizedBox(width: 8),
                                      Text('Add time interval'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'option6',
                                  child: Row(
                                    children: [
                                      Icon(Icons.timelapse_outlined),
                                      SizedBox(width: 8),
                                      Text('Focus right now?'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'option1',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Edit Task'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'option2',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outlined),
                                      SizedBox(width: 8),
                                      Text('Delete Task'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (state.isExpanded)
                            ...taskWithSubtasks.subtasks.map(
                              (subtask) => CheckboxListTile(
                                side: BorderSide(
                                  color: labelColor,
                                ),
                                activeColor: labelColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: subtask.isSubtaskCompleted,
                                onChanged: (value) {
                                  subtask.isSubtaskCompleted = value ?? false;
                                  onSubtasksChanged(taskWithSubtasks);
                                },
                                title: Text(
                                  subtask.title,
                                  style: TextStyle(
                                    decoration: subtask.isSubtaskCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: labelColor,
                                  ),
                                ),
                                secondary: IconButton(
                                  icon: Icon(
                                    Icons.delete_outlined,
                                    color: labelColor,
                                  ),
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete Subtask'),
                                          content: const Text(
                                              'Are you sure you want to delete this subtask?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (result == true) {
                                      taskWithSubtasks.subtasks.remove(subtask);
                                      onSubtasksChanged(taskWithSubtasks);
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Handle other states or errors here
            return SizedBox.shrink();
          }
        },
      ),
    );
  }
}
