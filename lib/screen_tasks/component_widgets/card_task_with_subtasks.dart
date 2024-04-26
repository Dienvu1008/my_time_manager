import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';
import 'package:my_time_manager/utils/utils.dart';

class TaskWithSubtasksCard extends StatefulWidget {
  final TaskWithSubtasks taskWithSubtasks;
  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;
  final bool Function(TaskWithSubtasks) isTaskWithSubtasksCardExpanded;
  final Function(TaskWithSubtasks) onTaskWithSubtasksCardExpanded;
  final bool isProVersion;
  const TaskWithSubtasksCard({
    Key? key,
    required this.taskWithSubtasks,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
    required this.isTaskWithSubtasksCardExpanded,
    required this.onTaskWithSubtasksCardExpanded,
    required this.isProVersion,
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
    final textTheme = Theme.of(context).textTheme;
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
                    contentPadding: const EdgeInsets.only(right:0, left: 8),
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.taskWithSubtasks.isImportant)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                    5),
                              ),
                              child: Text(
                                localizations!.important,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          Text(
                            widget.taskWithSubtasks.title,
                            style: widget.taskWithSubtasks.isCompleted
                                ? textTheme.labelLarge!.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: labelColor)
                                : textTheme.labelLarge!
                                    .copyWith(color: labelColor),
                          ),
                        ]),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_outlined, color: labelColor),
                      onSelected: (String result) {
                        if (result == 'edit') {
                          widget
                              .onTaskWithSubtasksEdit(widget.taskWithSubtasks);
                        } else if (result == 'delete') {
                          widget.onTaskWithSubtasksDelete(
                              widget.taskWithSubtasks);
                        } else if (result == 'completion') {
                          widget.onTaskWithSubtasksToggleComplete(
                              widget.taskWithSubtasks);
                        } else if (result == 'schedule') {
                          showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (BuildContext context) {
                                final EdgeInsets padding =
                                    MediaQuery.of(context).padding;
                                return Padding(
                                  padding: EdgeInsets.only(top: padding.top),
                                  child: ShowOrSetTimeIntervalsBottomSheet(
                                    title: widget.taskWithSubtasks.title,
                                    color: widget.taskWithSubtasks.color,
                                    description:
                                        widget.taskWithSubtasks.description,
                                    location: widget.taskWithSubtasks.location,
                                    targetType: TargetType.about,
                                    targetAtLeast: double.negativeInfinity,
                                    targetAtMost: double.infinity,
                                    unit: '',
                                    subtasks: widget.taskWithSubtasks.subtasks,
                                    taskWithSubtasksId:
                                        widget.taskWithSubtasks.id,
                                    isSetTimeIntervalPage: true,
                                  ),
                                );
                              });
                        } else if (result == 'expand') {
                          widget.onTaskWithSubtasksCardExpanded(
                              widget.taskWithSubtasks);
                        } else if (result == 'planned') {
                          showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              enableDrag: true,
                              builder: (BuildContext context) {
                                final EdgeInsets padding =
                                    MediaQuery.of(context).padding;
                                return Padding(
                                  padding: EdgeInsets.only(top: padding.top),
                                  child: ShowOrSetTimeIntervalsBottomSheet(
                                    title: widget.taskWithSubtasks.title,
                                    color: widget.taskWithSubtasks.color,
                                    description:
                                        widget.taskWithSubtasks.description,
                                    location: widget.taskWithSubtasks.location,
                                    targetType: TargetType.about,
                                    targetAtLeast: double.negativeInfinity,
                                    targetAtMost: double.infinity,
                                    unit: '',
                                    subtasks: widget.taskWithSubtasks.subtasks,
                                    taskWithSubtasksId:
                                        widget.taskWithSubtasks.id,
                                    isSetTimeIntervalPage: false,
                                  ),
                                );
                              });
                        } else if (result == 'focus_timer') {

                          if(widget.isProVersion){
                            showComingSoonDialog(context);} else {showWillBeAvaiableOnProVersionDialog(context);}
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'expand',
                          child: Row(
                            children: [
                              Icon(//_isExpanded
                                  widget.isTaskWithSubtasksCardExpanded(
                                              widget.taskWithSubtasks) ==
                                          true
                                      ? Icons.chevron_right
                                      : Icons.expand_more),
                              const SizedBox(width: 8),
                              //_isExpanded
                              widget.isTaskWithSubtasksCardExpanded(
                                          widget.taskWithSubtasks) ==
                                      true
                                  ? Expanded(
                                      child: Text(localizations!.hideSubTasks))
                                  : Expanded(
                                      child: Text(localizations!.showSubTasks),
                                    )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'completion',
                          child: Row(
                            children: [
                              Icon(widget.taskWithSubtasks.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.taskWithSubtasks.isCompleted
                                  ? Expanded(
                                      child:
                                          Text(localizations.markAsIncompleted))
                                  : Expanded(
                                      child:
                                          Text(localizations.markAsCompleted),
                                    )
                            ],
                          ),
                        ),
                            PopupMenuItem<String>(
                              value: 'schedule',
                              child: Row(
                                children: [
                                  const Icon(Icons.hourglass_empty_outlined),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(localizations.schedule),
                                  )
                                ],
                              ),
                            ),
                        PopupMenuItem<String>(
                          value: 'planned',
                          child: Row(
                            children: [
                              const Icon(Icons.event_note_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations.planned),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'focus_timer',
                          child: Row(
                            children: [
                              const Icon(Icons.timelapse_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations.focusRightNow),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations.editTask),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations.deleteTask),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  //if (_isExpanded)
                  if (widget.isTaskWithSubtasksCardExpanded(
                          widget.taskWithSubtasks) ==
                      true)
                    ...widget.taskWithSubtasks.subtasks.reversed.map(
                      (subtask) => CheckboxListTile(
                        contentPadding: const EdgeInsets.only(right:0, left: 8),
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
                                  content: Text(localizations
                                      .areYouSureYouWantToDeleteThisSubtask),
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
