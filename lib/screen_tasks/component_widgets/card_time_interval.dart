import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_measurable_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import 'package:my_time_manager/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeIntervalCard extends StatefulWidget {
  final TimeInterval timeInterval;
  final Function(TimeInterval) onTimeIntervalEdit;
  final Function(TimeInterval) onTimeIntervalDelete;
  final Function(TimeInterval) onTimeIntervalToggleComplete;
  final Function(TimeInterval) onSubtasksChanged;
  final Function(TimeInterval) onHasBeenDoneUpdate;

  const TimeIntervalCard({
    Key? key,
    required this.timeInterval,
    required this.onTimeIntervalEdit,
    required this.onTimeIntervalDelete,
    required this.onTimeIntervalToggleComplete,
    required this.onSubtasksChanged,
    required this.onHasBeenDoneUpdate,
  }) : super(key: key);

  @override
  _TimeIntervalCardState createState() => _TimeIntervalCardState();
}

class _TimeIntervalCardState extends State<TimeIntervalCard> {

  bool _isExpanded = false;
  String _formattedStartDate = '--/--/----';
  String _formattedStartTime = '--:--';
  String _formattedEndDate = '--/--/----';
  String _formattedEndTime = '--:--';

  @override
  void initState() {
    super.initState();
    //_loadIsExpanded();
  }

  // void _loadIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final isExpanded =
  //       prefs.getBool('isExpanded_${widget.timeInterval.id}') ?? true;
  //   if (mounted) {
  //     setState(() {
  //       _isExpanded = isExpanded;
  //     });
  //   }
  // }

  // void _saveIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setBool('isExpanded_${widget.timeInterval.id}', _isExpanded);
  // }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final timeIntervalColor = widget.timeInterval.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: timeIntervalColor)
        : ColorScheme.light(primary: timeIntervalColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    final textTheme = Theme.of(context).textTheme.apply(bodyColor: labelColor);

    if (widget.timeInterval.startDate != null) {
      _formattedStartDate = DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(widget.timeInterval.startDate!);
    } else {
      _formattedStartDate = '--/--/----';
    }

    if (widget.timeInterval.startTime != null) {
      _formattedStartTime = widget.timeInterval.startTime!.format(context);
    } else {
      _formattedStartTime = '--:--';
    }

    if (widget.timeInterval.endDate != null) {
      _formattedEndDate = DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(widget.timeInterval.endDate!);
    } else {
      _formattedEndDate = '--/--/----';
    }

    if (widget.timeInterval.endTime != null) {
      _formattedEndTime = widget.timeInterval.endTime!.format(context);
    } else {
      _formattedEndTime = '--:--';
    }

    return Card(
      color: backgroundColor,
      //   child: Container(
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: widget.timeInterval.startDate != null && widget.timeInterval.endDate == null
      //         ? [backgroundColor, Colors.white]
      //         : [Colors.white, backgroundColor],
      //     begin: Alignment.topCenter,
      //     end: Alignment.bottomCenter,
      //   ),
      // child: Container(
      //   decoration: BoxDecoration(
      //     color: widget.timeInterval.startDate != null &&
      //             widget.timeInterval.endDate != null
      //         ? backgroundColor
      //         : null,
      //     gradient: widget.timeInterval.startDate != null &&
      //             widget.timeInterval.endDate != null
      //         ? null
      //         : LinearGradient(
      //             colors: widget.timeInterval.startDate != null &&
      //                     widget.timeInterval.endDate == null
      //                 ? [backgroundColor, Colors.white]
      //                 : [Colors.white, backgroundColor],
      //             begin: Alignment.topCenter,
      //             end: Alignment.bottomCenter,
      //           ),
      //   ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onTimeIntervalEdit(widget.timeInterval),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 0.1),
                    dense: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8.0,
                          children: <Widget>[
                            if (widget.timeInterval.isImportant == true)
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
                            if (widget.timeInterval.isGone == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(
                                      5), // bo tròn viền tại đây
                                ),
                                child: Text(
                                  localizations!.gone,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            if (widget.timeInterval.isInProgress == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(
                                      5), // bo tròn viền tại đây
                                ),
                                child: Text(
                                  localizations!.inProgress,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            if (widget.timeInterval.isToday == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(
                                      5), // bo tròn viền tại đây
                                ),
                                child: Text(
                                  localizations!.today,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        RichText(
                          text: TextSpan(
                            style: widget.timeInterval.isCompleted
                                ? textTheme.labelMedium!.copyWith(
                                    decoration: TextDecoration.lineThrough)
                                : textTheme.labelMedium,
                            text: _formattedStartDate == _formattedEndDate
                                ? '${localizations!.from} $_formattedStartDate: $_formattedStartTime ${localizations.to} $_formattedEndTime'
                                : '${localizations!.from} $_formattedStartDate: $_formattedStartTime ${localizations.to} $_formattedEndDate: $_formattedEndTime',
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.timeInterval.title,
                          style: TextStyle(
                            color: labelColor,
                            decoration: widget.timeInterval.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        // if (widget.timeInterval.description.isNotEmpty)
                        //   Text(
                        //     widget.timeInterval.description,
                        //     style: TextStyle(color: labelColor),
                        //   ),
                        Visibility(
                          visible:
                              widget.timeInterval.measurableTaskId != null &&
                                  _isExpanded,
                          child: Column(
                            children: [
                              if (widget.timeInterval.targetType ==
                                  TargetType.about)
                                Text(
                                  '${localizations.targetAbout} ${widget.timeInterval.targetAtLeast} ${localizations.to} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                              if (widget.timeInterval.targetType ==
                                  TargetType.atLeast)
                                Text(
                                  '${localizations.targetAtLeast} ${widget.timeInterval.targetAtLeast} ${widget.timeInterval.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                              if (widget.timeInterval.targetType ==
                                  TargetType.atMost)
                                Text(
                                  '${localizations.targetAtMost} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_outlined, color: labelColor),
                      onSelected: (String result) async {
                        if (result == 'sync_from_task') {
                          showComingSoonDialog(context);
                        } else if (result == 'delete_time_interval') {
                          widget.onTimeIntervalDelete(widget.timeInterval);
                        } else if (result == 'option3') {
                          widget.onTimeIntervalToggleComplete(
                              widget.timeInterval);
                        } else if (result == 'go_to_main_task') {
                          final DatabaseManager databaseManager =
                              DatabaseManager();
                          if (widget.timeInterval.taskWithSubtasksId != null) {
                            final id = widget.timeInterval.taskWithSubtasksId;
                            final TaskWithSubtasks taskWithSubtasks =
                                await databaseManager.taskWithSubtasks(id!);
                            final TaskList taskList = await databaseManager
                                .taskList(taskWithSubtasks.taskListId);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddOrEditTaskWithSubtasksPage(
                                  taskList: taskList,
                                  taskWithSubtasks: taskWithSubtasks,
                                ),
                              ),
                            );
                          } else if (widget.timeInterval.measurableTaskId !=
                              null) {
                            final id = widget.timeInterval.measurableTaskId;
                            final MeasurableTask measurableTask =
                                await databaseManager.measurableTask(id!);
                            final TaskList taskList = await databaseManager
                                .taskList(measurableTask.taskListId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddOrEditMeasurableTaskPage(
                                  taskList: taskList,
                                  measurableTask: measurableTask,
                                ),
                              ),
                            );
                          } else if (widget.timeInterval.taskId != null) {
                            final id = widget.timeInterval.taskId;
                            final Task task = await databaseManager.task(id!);
                            final TaskList taskList =
                                await databaseManager.taskList(task.taskListId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddOrEditTaskPage(
                                  taskList: taskList,
                                  task: task,
                                ),
                              ),
                            );
                          }
                        } else if (result == 'option5') {
                          setState(() => _isExpanded = !_isExpanded);
                          //_saveIsExpanded();
                          //widget.onSubtasksDisplayChanged;
                        } else if (result == 'option6') {
                          setState(() => _isExpanded = !_isExpanded);
                          //_saveIsExpanded();
                          //widget.onSubtasksDisplayChanged;
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        if (widget.timeInterval.taskWithSubtasksId != null)
                          PopupMenuItem<String>(
                            value: 'option5',
                            child: Row(
                              children: [
                                Icon(_isExpanded
                                    ? Icons.chevron_right
                                    : Icons.expand_more),
                                const SizedBox(width: 8),
                                _isExpanded
                                    ? Text(localizations.hideSubTasks)
                                    : Text(localizations.showSubTasks),
                              ],
                            ),
                          ),
                        if (widget.timeInterval.measurableTaskId != null)
                          PopupMenuItem<String>(
                            value: 'option6',
                            child: Row(
                              children: [
                                Icon(_isExpanded
                                    ? Icons.chevron_right
                                    : Icons.expand_more),
                                const SizedBox(width: 8),
                                _isExpanded
                                    ? Text(localizations.hideTargetInfor)
                                    : Text(localizations.showTargetInfor),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'option3',
                          child: Row(
                            children: [
                              Icon(widget.timeInterval.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.timeInterval.isCompleted
                                  ? Expanded(
                                      child: Text(
                                          localizations.markAsIncompletedInThisTimeInterval))
                                  : Expanded(
                                      child: Text(
                                          localizations.markAsCompletedInThisTimeInterval),
                                    )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'sync_from_task',
                          child: Row(
                            children: [
                              const Icon(Icons.copy_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    localizations.syncDetailsFromTaskToThisTimeInterval),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'go_to_main_task',
                          child: Row(
                            children: [
                              const Icon(Icons.read_more_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.goToMainTask),)
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'option1',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.editThisTimeInterval),)
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_time_interval',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(localizations.deleteThisTimeInterval),)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _isExpanded &&
                        widget.timeInterval.measurableTaskId != null,
                    child: ListTile(
                      title: ActionChip(
                        label: Text(
                          '${localizations.hasBeenDone} ${widget.timeInterval.howMuchHasBeenDone} ${widget.timeInterval.unit}',
                        ),
                        onPressed: () =>
                            widget.onHasBeenDoneUpdate(widget.timeInterval),
                      ),
                    ),
                  ),
                  if (_isExpanded &&
                      widget.timeInterval.taskWithSubtasksId != null)
                    SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          ...widget.timeInterval.subtasks.map(
                            (subtask) => CheckboxListTile(
                              side: BorderSide(
                                color: labelColor,
                              ),
                              activeColor: labelColor,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: subtask.isSubtaskCompleted,
                              onChanged: (value) {
                                subtask.isSubtaskCompleted = value ?? false;
                                widget.onSubtasksChanged(widget.timeInterval);
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
                                        title: Text(localizations.deleteSubtask),
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
                                    widget.timeInterval.subtasks
                                        .remove(subtask);
                                    widget
                                        .onSubtasksChanged(widget.timeInterval);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      //),
    );
    //}
    //;
  }
}
