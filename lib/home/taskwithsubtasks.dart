import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// void main() {
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Interval',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TaskForm(),
    );
  }
}

class Subtask {
  bool isSubtaskCompleted;
  String title;

  Subtask({
    required this.isSubtaskCompleted,
    required this.title,
  });
}

class TaskWithSubtasks {
  String id;
  String title;
  String description;
  bool isCompleted;
  List<Subtask> subtasks;

  TaskWithSubtasks({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.subtasks,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4();

  void updateCompletionStatus() {
    isCompleted = subtasks.every((subtask) => subtask.isSubtaskCompleted);
  }
}

class TaskForm extends StatefulWidget {
  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<Subtask> _subtasks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
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
            SizedBox(height: 16),
            Text('Subtasks', style: Theme.of(context).textTheme.headline6),
            ..._subtasks.map((subtask) => ListTile(
                  title: Text(subtask.title),
                  trailing: Checkbox(
                    value: subtask.isSubtaskCompleted,
                    onChanged: (value) {
                      setState(() {
                        subtask.isSubtaskCompleted = value ?? false;
                      });
                    },
                  ),
                )),
            TextButton.icon(
              onPressed: () async {
                final title = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Add Subtask'),
                    content: TextFormField(
                      decoration: InputDecoration(labelText: 'Title'),
                      autofocus: true,
                      onFieldSubmitted: (value) =>
                          Navigator.pop(context, value),
                    ),
                  ),
                );
                if (title != null && title.isNotEmpty) {
                  setState(() {
                    _subtasks
                        .add(Subtask(isSubtaskCompleted: false, title: title));
                  });
                }
              },
              icon: Icon(Icons.add),
              label: Text('Add Subtask'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final task = TaskWithSubtasks(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    subtasks: List<Subtask>.from(_subtasks.map((subtask) =>
                        Subtask(
                            isSubtaskCompleted: subtask.isSubtaskCompleted,
                            title: subtask.title))),
                  );
                  task.updateCompletionStatus();
                  // TODO: Save task to database or send to server
                  //Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TaskDetails(task: task)),
                  );
                }
              },
              child: Text('Save Task', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetails extends StatelessWidget {
  final TaskWithSubtasks task;

  const TaskDetails({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headline5),
          SizedBox(height: 8),
          Text(task.description),
          SizedBox(height: 16),
          Text('Subtasks', style: Theme.of(context).textTheme.headline6),
          ...task.subtasks.map((subtask) => ListTile(
                title: Text(subtask.title),
                trailing: subtask.isSubtaskCompleted
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
              )),
        ],
      ),
    );
  }
}
