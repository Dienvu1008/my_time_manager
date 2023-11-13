import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';
import 'package:my_time_manager/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskWithSubtasksCard extends StatefulWidget {
  final TaskWithSubtasks taskWithSubtasks;
  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;
  final bool Function(TaskWithSubtasks) isTaskWithSubtasksCardExpanded;
  final Function(TaskWithSubtasks) onTaskWithSubtasksCardExpanded;
  const TaskWithSubtasksCard({
    Key? key,
    required this.taskWithSubtasks,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
    required this.isTaskWithSubtasksCardExpanded,
    required this.onTaskWithSubtasksCardExpanded,
  }) : super(key: key);

  @override
  _TaskWithSubtasksCardState createState() => _TaskWithSubtasksCardState();
}

class _TaskWithSubtasksCardState extends State<TaskWithSubtasksCard> {
  // static Color contrastColor(Color color) {
  //   final brightness = ThemeData.estimateBrightnessForColor(color);
  //   switch (brightness) {
  //     case Brightness.dark:
  //       return Colors.white;
  //     case Brightness.light:
  //       return Colors.black;
  //   }
  // }

  //bool _isExpanded = true;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadIsExpanded();
  // }

  // void _loadIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final isExpanded =
  //       prefs.getBool('isExpanded_${widget.taskWithSubtasks.id}') ?? true;
  //   if (mounted) {
  //     setState(() {
  //       _isExpanded = isExpanded;
  //     });
  //   }
  // }

  // void _saveIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setBool('isExpanded_${widget.taskWithSubtasks.id}', _isExpanded);
  // }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
                    // title: Text(
                    //   widget.taskWithSubtasks.title,
                    //   style: TextStyle(
                    //     color: labelColor,
                    //     decoration: widget.taskWithSubtasks.isCompleted
                    //         ? TextDecoration.lineThrough
                    //         : null,
                    //   ),
                    // ),
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.taskWithSubtasks.isImportant)
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
                            widget.taskWithSubtasks.title,
                            style: TextStyle(
                              color: labelColor,
                              decoration: widget.taskWithSubtasks.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ]),
                    // subtitle: widget.taskWithSubtasks.description.isNotEmpty
                    //     ? Text(
                    //         widget.taskWithSubtasks.description,
                    //         style: TextStyle(color: labelColor),
                    //       )
                    //     : null,
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
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                ShowOrSetTimeIntervalsBottomSheet(
                              title: widget.taskWithSubtasks.title,
                              color: widget.taskWithSubtasks.color,
                              description: widget.taskWithSubtasks.description,
                              location: widget.taskWithSubtasks.location,
                              targetType: TargetType.about,
                              targetAtLeast: double.negativeInfinity,
                              targetAtMost: double.infinity,
                              unit: '',
                              subtasks: widget.taskWithSubtasks.subtasks,
                              taskWithSubtasksId: widget.taskWithSubtasks.id,
                              isSetTimeIntervalPage: true,
                            ),
                          );
                        } else if (result == 'option5') {
                          widget.onTaskWithSubtasksCardExpanded(widget.taskWithSubtasks);
                        } else if (result == 'planned') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                ShowOrSetTimeIntervalsBottomSheet(
                              title: widget.taskWithSubtasks.title,
                              color: widget.taskWithSubtasks.color,
                              description: widget.taskWithSubtasks.description,
                              location: widget.taskWithSubtasks.location,
                              targetType: TargetType.about,
                              targetAtLeast: double.negativeInfinity,
                              targetAtMost: double.infinity,
                              unit: '',
                              subtasks: widget.taskWithSubtasks.subtasks,
                              taskWithSubtasksId: widget.taskWithSubtasks.id,
                              isSetTimeIntervalPage: false,
                            ),
                          );
                        } else if (result == 'focus_timer') { showComingSoonDialog(context);}
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'option5',
                          child: Row(
                            children: [
                              Icon(//_isExpanded
                              widget.isTaskWithSubtasksCardExpanded(widget.taskWithSubtasks) == true
                                  ? Icons.chevron_right
                                  : Icons.expand_more),
                              const SizedBox(width: 8),
                              //_isExpanded
                              widget.isTaskWithSubtasksCardExpanded(widget.taskWithSubtasks) == true
                                  ? Expanded(child: Text(localizations!.hideSubTasks))
                                  : Expanded(child: Text(localizations!.showSubTasks),)
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
                                  ? Expanded(child: Text(localizations.markAsIncompleted))
                                  : Expanded(child: Text(localizations.markAsCompleted),)
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
                        // const PopupMenuItem<String>(
                        //   value: 'option4',
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.hourglass_empty),
                        //       SizedBox(width: 8),
                        //       Text('Schedule'),
                        //     ],
                        //   ),
                        // ),
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
                          value: 'option1',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.editTask),)
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'option2',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.deleteTask),)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  //if (_isExpanded)
                  if (widget.isTaskWithSubtasksCardExpanded(widget.taskWithSubtasks) == true)
                    ...widget.taskWithSubtasks.subtasks.reversed.map(
                      (subtask) => CheckboxListTile(
                        dense: true,
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
                                  title: Text(localizations!.deleteSubtask),
                                  content: Text(
                                      localizations.areYouSureYouWantToDeleteThisSubtask),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(localizations.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(localizations.delete),
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
