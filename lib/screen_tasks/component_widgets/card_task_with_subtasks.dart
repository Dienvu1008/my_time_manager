import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_set_time_intervals.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_time_intervals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskWithSubtasksCard extends StatefulWidget {
  final TaskWithSubtasks taskWithSubtasks;
  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;
  const TaskWithSubtasksCard({
    Key? key,
    required this.taskWithSubtasks,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
  }) : super(key: key);

  @override
  _TaskWithSubtasksCardState createState() => _TaskWithSubtasksCardState();
}

class _TaskWithSubtasksCardState extends State<TaskWithSubtasksCard> {
  static Color contrastColor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    switch (brightness) {
      case Brightness.dark:
        return Colors.white;
      case Brightness.light:
        return Colors.black;
    }
  }

  bool _isExpanded = true;
  //bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIsExpanded();
  }

  void _loadIsExpanded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isExpanded =
        prefs.getBool('isExpanded_${widget.taskWithSubtasks.id}') ?? true;
    if (mounted) {
      setState(() {
        _isExpanded = isExpanded;
      });
    }
  }

  void _saveIsExpanded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isExpanded_${widget.taskWithSubtasks.id}', _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final taskWithSubtasksColor = widget.taskWithSubtasks.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: taskWithSubtasksColor)
        : ColorScheme.light(primary: taskWithSubtasksColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    return Card(
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  widget.onTaskWithSubtasksEdit(widget.taskWithSubtasks),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      widget.taskWithSubtasks.title,
                      style: TextStyle(
                        color: labelColor,
                        decoration: widget.taskWithSubtasks.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: widget.taskWithSubtasks.description.isNotEmpty
                        ? Text(
                            widget.taskWithSubtasks.description,
                            style: TextStyle(color: labelColor),
                          )
                        : null,
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_outlined, color: labelColor),
                      onSelected: (String result) {
                        if (result == 'option1') {
                          widget
                              .onTaskWithSubtasksEdit(widget.taskWithSubtasks);
                        } else if (result == 'option2') {
                          widget.onTaskWithSubtasksDelete(
                              widget.taskWithSubtasks);
                        } else if (result == 'option3') {
                          widget.onTaskWithSubtasksToggleComplete(
                              widget.taskWithSubtasks);
                        } else if (result == 'option4') {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //       builder: (context) => TimeIntervalPage(
                          //           taskWithSubtasks: widget.taskWithSubtasks)),
                          // );
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                SetTimeIntervalBottomSheet(
                              taskWithSubtasksId: widget.taskWithSubtasks.id,
                            ),
                          );
                        } else if (result == 'option5') {
                          setState(() => _isExpanded = !_isExpanded);
                          _saveIsExpanded();
                        } else if (result == 'planned') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                ShowTimeIntervalsBottomSheet(
                                    taskWithSubtasksId:
                                        widget.taskWithSubtasks.id),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'option5',
                          child: Row(
                            children: [
                              Icon(_isExpanded
                                  ? Icons.chevron_right
                                  : Icons.expand_more),
                              const SizedBox(width: 8),
                              _isExpanded
                                  ? const Text('Hide sub-tasks')
                                  : const Text('Show sub-tasks'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'option3',
                          child: Row(
                            children: [
                              Icon(widget.taskWithSubtasks.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.taskWithSubtasks.isCompleted
                                  ? const Text('Mark as incompleted')
                                  : const Text('Mark as completed'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'planned',
                          child: Row(
                            children: [
                              Icon(Icons.event_note_outlined),
                              SizedBox(width: 8),
                              Text('Planned'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option4',
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty),
                              SizedBox(width: 8),
                              Text('Schedule'),
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
                  if (_isExpanded)
                    ...widget.taskWithSubtasks.subtasks.map(
                      (subtask) => CheckboxListTile(
                        side: BorderSide(
                          color: labelColor,
                        ),
                        activeColor: labelColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: subtask.isSubtaskCompleted,
                        onChanged: (value) {
                          //_isLoading = false;
                          subtask.isSubtaskCompleted = value ?? false;
                          widget.onSubtasksChanged(widget.taskWithSubtasks);
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
                                  title: Text('Delete Subtask'),
                                  content: Text(
                                      'Are you sure you want to delete this subtask?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (result == true) {
                              widget.taskWithSubtasks.subtasks.remove(subtask);
                              widget.onSubtasksChanged(widget.taskWithSubtasks);
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
    //}
    //;
  }
}
