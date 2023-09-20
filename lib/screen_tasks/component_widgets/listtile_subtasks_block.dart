import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';

class SubtasksListTile extends StatefulWidget {
  final List<Subtask> subtasks;
  final Function showAddSubtaskDialog;
  final Function onSubtaskToggleComplete;
  final Function onSubtaskEdit;
  final Function onSubtaskDelete;

  SubtasksListTile(
      {required this.subtasks,
      required this.showAddSubtaskDialog,
      required this.onSubtaskToggleComplete,
      required this.onSubtaskEdit,
      required this.onSubtaskDelete});

  @override
  _SubtasksListTileState createState() => _SubtasksListTileState();
}

class _SubtasksListTileState extends State<SubtasksListTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.subtasks
            .map((subtask) => CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: subtask.isSubtaskCompleted,
                  onChanged: (value) {
                    setState(() => subtask.isSubtaskCompleted = value ?? false);
                    widget.onSubtaskToggleComplete(subtask);
                  },
                  title: GestureDetector(
                    onTap: () async {
                      final TextEditingController _controller =
                          TextEditingController();
                      _controller.text = subtask.title;
                      final newTitle = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Edit Subtask'),
                            content: TextField(
                              controller: _controller,
                              decoration: InputDecoration(labelText: 'Title'),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, _controller.text),
                                child: Text('Save'),
                              ),
                            ],
                          );
                        },
                      );
                      if (newTitle != null) {
                        setState(() {
                          subtask.title = newTitle;
                        });
                      }
                    },
                    child: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.isSubtaskCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        widget.subtasks.remove(subtask);
                      });
                    },
                  ),
                ))
            .toList(),
        const SizedBox(height: 24.0),
        Row(children: [
          ElevatedButton(
            onPressed: () => widget.showAddSubtaskDialog(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 4),
                Text('Add Subtask'),
              ],
            ),
          )
        ]),
      ],
    );
  }
}
