import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';
import 'package:my_time_manager/utils/utils.dart';

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
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTaskEdit(widget.task),
                child: ListTile(
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.task.isImportant)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                    5), // bo tròn viền tại đây
                              ),
                              child: Text(
                                localizations!.important,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          Text(
                            widget.task.title,
                            style: TextStyle(
                              color: labelColor,
                              decoration: widget.task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ]),
                    // subtitle: widget.task.description.isNotEmpty
                    //     ? Text(
                    //         widget.task.description,
                    //         style: TextStyle(color: labelColor),
                    //       )
                    //     : null,
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
                        } else if (result == 'planned') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                ShowOrSetTimeIntervalsBottomSheet(
                              title: widget.task.title,
                              color: widget.task.color,
                              description: widget.task.description,
                              location: widget.task.location,
                              targetType: TargetType.about,
                              targetAtLeast: double.negativeInfinity,
                              targetAtMost: double.infinity,
                              unit: '',
                              subtasks: [],
                              taskId: widget.task.id,
                              isSetTimeIntervalPage: false,
                            ),
                          );
                        } else if (result == 'focus_timer') {
                          showComingSoonDialog(context);
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
                                  ? Expanded(child: Text(localizations!.markAsIncompleted))
                                  : Expanded(child: Text(localizations!.markAsCompleted),)
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'planned',
                          child: Row(
                            children: [
                              const Icon(Icons.event_note_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.planned),)
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'focus_timer',
                          child: Row(
                            children: [
                              const Icon(Icons.timelapse_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.focusRightNow),)
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'edit_task',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.editTask),)
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_task',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.deleteTask),)
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
