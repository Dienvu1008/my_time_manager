import 'package:flutter/material.dart';

class TaskListListTile extends StatelessWidget {
  final String title;
  final TextStyle? style;

  TaskListListTile({required this.title, required this.style});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(title, style: style),
        ),
        const SizedBox(height: 8.0),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}
