import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// void main() {
  
//     sqfliteFfiInit();
//     databaseFactory = databaseFactoryFfi;
  
//   runApp(MyApp());
// }

class TaskList {
  final int id;
  final String title;
  final String description;

  TaskList({required this.id, required this.title, required this.description});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<TaskList> _taskLists = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late Database _database;

  @override
  void initState() {
    super.initState();
    _loadTaskLists();
  }

  Future<void> _loadTaskLists() async {
    // Load task lists from sqflite database
    // Replace with your own code to load task lists from sqflite database
    //     _database = await openDatabase(
    //   join(await getDatabasesPath(), 'strings.db'),
    //   onCreate: (db, version) {
    //     return db.execute(
    //       "CREATE TABLE strings(id INTEGER PRIMARY KEY, string TEXT)",
    //     );
    //   },
    //   version: 1,
    // );

    final Database db = await openDatabase('my_db.db');
    final List<Map<String, dynamic>> maps = await db.query('task_lists');
    setState(() {
      _taskLists = List.generate(maps.length, (i) {
        return TaskList(
          id: maps[i]['id'],
          title: maps[i]['title'],
          description: maps[i]['description'],
        );
      });
    });

    // Load task list order from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList('order');
    if (order != null) {
      setState(() {
        _taskLists.sort((a, b) => order.indexOf(a.id.toString()).compareTo(order.indexOf(b.id.toString())));
      });
    }
  }

  Future<void> _saveTaskListOrder() async {
    // Save task list order to shared preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('order', _taskLists.map((e) => e.id.toString()).toList());
  }

  Future<void> _addTaskList(TaskList taskList) async {
    // Add new task list to sqflite database
    // Replace with your own code to add new task list to sqflite database
    final Database db = await openDatabase('my_db.db');
    await db.insert(
      'task_lists',
      taskList.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    setState(() {
      _taskLists.insert(0, taskList);
    });
    await _saveTaskListOrder();
  }

  Future<void> _deleteTaskList(TaskList taskList) async {
    // Delete task list from sqflite database
    // Replace with your own code to delete task list from sqflite database
    final Database db = await openDatabase('my_db.db');
    await db.delete(
      'task_lists',
      where: "id = ?",
      whereArgs: [taskList.id],
    );

    setState(() {
      _taskLists.remove(taskList);
    });
    await _saveTaskListOrder();
  }

  Future<void> _updateTaskList(TaskList oldTaskList, TaskList newTaskList) async {
    // Update task list in sqflite database
    // Replace with your own code to update task list in sqflite database
    final Database db = await openDatabase('my_db.db');
    await db.update(
      'task_lists',
      newTaskList.toMap(),
      where: "id = ?",
      whereArgs: [oldTaskList.id],
    );

    setState(() {
      int index = _taskLists.indexOf(oldTaskList);
      if (index != -1) {
        _taskLists[index] = newTaskList;
      }
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Task'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Add'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Add new task list
                    await _addTaskList(TaskList(
                      id: DateTime.now().millisecondsSinceEpoch,
                      title: _titleController.text,
                      description: _descriptionController.text,
                    ));
                    // Clear text fields
                    _titleController.clear();
                    _descriptionController.clear();
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  void _showEditTaskDialog(BuildContext context, TaskList taskList) {
    _titleController.text = taskList.title;
    _descriptionController.text = taskList.description;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Edit Task'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller:_descriptionController,
                    decoration: InputDecoration(labelText:'Description'),
                  ),
                ],
              ),
            ),
            actions:<Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Update task list
                    await _updateTaskList(taskList, TaskList(id : taskList.id, title :_titleController.text, description :_descriptionController.text));
                    // Clear text fields
                    _titleController.clear();
                    _descriptionController.clear();
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:Scaffold(
        appBar : AppBar(title : Text('Task List')),
        body : ReorderableListView.builder(
          itemCount :_taskLists.length,
          itemBuilder :(BuildContext context, int index){
            final taskList =_taskLists[index];
            return Dismissible(key : ValueKey(taskList.id),
              background : Container(color : Colors.red),
              onDismissed :(direction){
                // Delete task list
                _deleteTaskList(taskList);
              },
              child : ListTile(title : Text(taskList.title),
                subtitle :Text(taskList.description),
                onTap :(){
                  // Show edit task dialog
                  _showEditTaskDialog(context, taskList);
                },
              ),
            );
          },
          onReorder :(int oldIndex, int newIndex){
            setState((){
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final TaskList item =_taskLists.removeAt(oldIndex);
              _taskLists.insert(newIndex, item);
            });
            _saveTaskListOrder();
          },
        ),
        floatingActionButton : FloatingActionButton(child : Icon(Icons.add),
          onPressed :(){
            // Show add task dialog
            _showAddTaskDialog(context);
          },
        ),
      ),
    );
  }
}



