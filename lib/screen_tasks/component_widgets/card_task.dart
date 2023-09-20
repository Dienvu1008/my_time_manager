import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_time_interval.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;
  final Function(Task) onTaskToggleComplete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTaskToggleComplete,
  }) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
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
    final localizations = AppLocalizations.of(context);
    final taskColor = widget.task.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: taskColor)
        : ColorScheme.light(primary: taskColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);

    return Card(
        color: backgroundColor,
        child: Row(
          children: [
            // Expanded(
            //     flex: 1,
            //     child: Container(
            //       decoration: BoxDecoration(
            //         color: backgroundColor,
            //       ),
            //     )),
            Expanded(
              //flex: 19,
              child: GestureDetector(
                onTap: () => widget.onTaskEdit(widget.task),
                child: ListTile(
                    title: Text(
                      widget.task.title,
                      style: TextStyle(
                        color: labelColor,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: widget.task.description.isNotEmpty
                        ? Text(
                            widget.task.description,
                            style: TextStyle(color: labelColor),
                          )
                        : null,
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: labelColor),
                      onSelected: (String result) {
                        if (result == 'edit_task') {
                          widget.onTaskEdit(widget.task);
                        } else if (result == 'delete_task') {
                          widget.onTaskDelete(widget.task);
                        } else if (result == 'mark_completion') {
                          widget.onTaskToggleComplete(widget.task);
                        } else if (result == 'schedule') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    TimeIntervalPage(task: widget.task)),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'mark_completion',
                          child: Row(
                            children: [
                              Icon(widget.task.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.task.isCompleted
                                  ? const Text('Mark as incompleted')
                                  : const Text('Mark as completed'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'schedule',
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty),
                              SizedBox(width: 8),
                              Text('Schedule'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'focus_timer',
                          child: Row(
                            children: [
                              Icon(Icons.timelapse_outlined),
                              SizedBox(width: 8),
                              Text('Focus right now?'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'edit_task',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Text(localizations!.editTask),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_task',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined),
                              const SizedBox(width: 8),
                              Text(localizations.deleteTask),
                            ],
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          ],
        ));
  }
}