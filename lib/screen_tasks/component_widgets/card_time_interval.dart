import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/attached_notes_view.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task.dart';
import 'package:my_time_manager/utils/utils.dart';

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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onTimeIntervalEdit(widget.timeInterval),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(right:0, left: 8),
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
                            // Icon chuông cho biết interval này có đặt nhắc.
                            if (widget
                                .timeInterval.reminderMinutesBefore.isNotEmpty)
                              Icon(
                                Icons.notifications_active_outlined,
                                size: 14,
                                color: labelColor,
                              ),
                          ],
                        ),
                        RichText(
                          text: TextSpan(
                            style: widget.timeInterval.isCompleted
                                ? textTheme.labelMedium!.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.bold)
                                : textTheme.labelMedium,
                            text: _formattedStartDate == _formattedEndDate
                                ? '$_formattedStartTime ${localizations!.to} $_formattedEndTime'
                                : '$_formattedStartTime ${localizations!.to} $_formattedEndDate: $_formattedEndTime',
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.timeInterval.title,
                          style: widget.timeInterval.isCompleted
                              ? textTheme.labelLarge!.copyWith(
                                  decoration: TextDecoration.lineThrough)
                              : textTheme.labelLarge,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_outlined, color: labelColor),
                      onSelected: (String result) async {
                        if (result == 'sync_from_task') {
                          showComingSoonDialog(context);
                        } else if(result == 'option1'){
                          widget.onTimeIntervalEdit(widget.timeInterval);
                        }
                        else if (result == 'delete_time_interval') {
                          widget.onTimeIntervalDelete(widget.timeInterval);
                        } else if (result == 'option3') {
                          widget.onTimeIntervalToggleComplete(
                              widget.timeInterval);
                        } else if (result == 'go_to_main_task') {
                          final taskRepository = context.read<TaskRepository>();
                          final taskListRepository =
                              context.read<TaskListRepository>();
                          if (widget.timeInterval.taskId != null) {
                            final id = widget.timeInterval.taskId;
                            final Task task =
                                await taskRepository.getTask(id!);
                            final TaskList? taskList = task.taskListId == null
                                ? null
                                : await taskListRepository
                                    .getTaskList(task.taskListId!);
                            if (!context.mounted) return;
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
                        if (widget.timeInterval.subtasks.isNotEmpty)
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
                        if (widget.timeInterval.unit.isNotEmpty)
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
                                      child: Text(localizations
                                          .markAsIncompletedInThisTimeInterval))
                                  : Expanded(
                                      child: Text(localizations
                                          .markAsCompletedInThisTimeInterval),
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
                                child: Text(localizations
                                    .syncDetailsFromTaskToThisTimeInterval),
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
                              Expanded(
                                child: Text(localizations.goToMainTask),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'option1',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations.editThisTimeInterval),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_time_interval',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child:
                                    Text(localizations.deleteThisTimeInterval),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded &&
                      (widget.timeInterval.unit.isNotEmpty ||
                          widget.timeInterval.description.isNotEmpty ||
                          widget.timeInterval.location.isNotEmpty ||
                          widget.timeInterval.noteIds.isNotEmpty))
                    ListTile(
                      title: Column(
                        children: [
                          if (widget.timeInterval.noteIds.isNotEmpty)
                            AttachedNotesView(
                              noteIds: widget.timeInterval.noteIds,
                              color: labelColor,
                              textStyle: textTheme.labelMedium!
                                  .copyWith(color: labelColor),
                            ),
                          if (widget.timeInterval.description.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.description_outlined,
                                    color: labelColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.timeInterval.description,
                                    style: textTheme.labelMedium!
                                        .copyWith(color: labelColor),
                                  ),
                                )
                              ],
                            ),
                          if (widget.timeInterval.location.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    color: labelColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.timeInterval.location,
                                    style: textTheme.labelMedium!
                                        .copyWith(color: labelColor),
                                  ),
                                ),
                              ],
                            ),
                          if (widget.timeInterval.unit.isNotEmpty &&
                              widget.timeInterval.targetType ==
                                  TargetType.about)
                            Text(
                              '${localizations.targetAbout} ${widget.timeInterval.targetAtLeast} ${localizations.to} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                              style: textTheme.labelMedium!
                                  .copyWith(color: labelColor),
                            ),
                          if (widget.timeInterval.unit.isNotEmpty &&
                              widget.timeInterval.targetType ==
                                  TargetType.atLeast)
                            Text(
                              '${localizations.targetAtLeast} ${widget.timeInterval.targetAtLeast} ${widget.timeInterval.unit}',
                              style: textTheme.labelMedium!
                                  .copyWith(color: labelColor),
                            ),
                          if (widget.timeInterval.unit.isNotEmpty &&
                              widget.timeInterval.targetType ==
                                  TargetType.atMost)
                            Text(
                              '${localizations.targetAtMost} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                              style: textTheme.labelMedium!
                                  .copyWith(color: labelColor),
                            ),
                          if (widget.timeInterval.unit.isNotEmpty)
                            Center(
                              child: ActionChip(
                                label: Text(
                                    '${localizations.hasBeenDone} ${widget.timeInterval.howMuchHasBeenDone} ${widget.timeInterval.unit}',
                                    style: textTheme.labelMedium!
                                        .copyWith(color: labelColor)),
                                onPressed: () => setState(
                                  () {
                                    widget.onHasBeenDoneUpdate(
                                        widget.timeInterval);
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_isExpanded &&
                      widget.timeInterval.subtasks.isNotEmpty)
                    SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          ...widget.timeInterval.subtasks.map(
                            (subtask) => CheckboxListTile(
                              contentPadding: const EdgeInsets.only(right:0, left: 8),
                              dense: true,
                              side: BorderSide(
                                color: labelColor,
                              ),
                              //activeColor: labelColor,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: subtask.isCompleted,
                              onChanged: (value) {
                                setState(() {
                                  subtask.isCompleted = value ?? false;
                                  widget.onSubtasksChanged(widget.timeInterval);
                                });
                              },
                              title: Text(subtask.title,
                                  style: subtask.isCompleted
                                      ? textTheme.labelMedium!.copyWith(
                                          decoration:
                                              TextDecoration.lineThrough)
                                      : textTheme.labelMedium!.copyWith(
                                          decoration: TextDecoration.none)),
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
                                        title:
                                            Text(localizations.deleteSubtask),
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
    );
  }
}
