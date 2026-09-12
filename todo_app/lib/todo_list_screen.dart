import 'package:flutter/material.dart';
import 'todo_item.dart';

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<String> _todos = [];

  void _addTodo(String todo) {
    setState(() {
      _todos.add(todo);
    });
  }

  void _removeTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          return TodoItem(
            text: _todos[index],
            onRemove: _removeTodo,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final todo = _getTodoFromUser();
          if (todo != null) {
            _addTodo(todo);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  String? _getTodoFromUser() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Todo'),
          content: TextField(
            controller: controller,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }
}
