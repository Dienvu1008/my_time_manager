import 'package:flutter/material.dart';

class TodoItem extends StatelessWidget {
  final String text;
  final Function(int) onRemove;

  TodoItem({required this.text, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(text),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => onRemove(_todos.indexOf(text)),
      ),
    );
  }
}
