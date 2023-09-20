import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';
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

  @override
  void initState() {
    super.initState();
    _loadIsExpanded();
  }

  void _loadIsExpanded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isExpanded =
        prefs.getBool('isExpanded_${widget.timeInterval.id}') ?? true;
    if (mounted) {
      setState(() {
        _isExpanded = isExpanded;
      });
    }
  }

  void _saveIsExpanded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isExpanded_${widget.timeInterval.id}', _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final taskWithSubtasksColor = widget.timeInterval.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: taskWithSubtasksColor)
        : ColorScheme.light(primary: taskWithSubtasksColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    String languageCode = Localizations.localeOf(context).languageCode;
    final String formattedStartDate = widget.timeInterval.startDate != null
        ? DateFormat('EEE, dd MMM, yyyy', languageCode).format(widget.timeInterval.startDate!)
        : '--/--/----';
    final textTheme = Theme.of(context).textTheme.apply(bodyColor: labelColor);

    return Card(
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            //flex: 19,
            child: GestureDetector(
              onTap: () => widget.onTimeIntervalEdit(widget.timeInterval),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    // title: Text(
                    //   widget.timeInterval.title,
                    //   style: TextStyle(
                    //     color: labelColor,
                    //     decoration: widget.timeInterval.isCompleted
                    //         ? TextDecoration.lineThrough
                    //         : null,
                    //   ),
                    // ),
                    // subtitle: widget.timeInterval.description.isNotEmpty
                    //     ? Text(
                    //         widget.timeInterval.description,
                    //         style: TextStyle(color: labelColor),
                    //       )
                    //     : null,(
                    title: Text(
                      '$formattedStartDate: ${widget.timeInterval.startTime!.format(context)} - ${widget.timeInterval.endTime!.format(context)}',
                      style: textTheme.labelSmall,
                    ),
                    subtitle:
                        // Text(
                        //   widget.timeInterval.title,
                        //   style: TextStyle(
                        //     color: labelColor,
                        //   ),
                        // ),
                        Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.timeInterval.title,
                          style: TextStyle(
                            color: labelColor,
                          ),
                        ),
                        if (widget.timeInterval.description.isNotEmpty)
                          Text(
                            widget.timeInterval.description,
                            style: TextStyle(color: labelColor),
                          ),
                        Visibility(
                          visible:
                              widget.timeInterval.measurableTaskId != null &&
                                  _isExpanded,
                          child: Column(
                            children: [
                              if (widget.timeInterval.targetType ==
                                  TargetType.about)
                                Text(
                                  'Target: about ${widget.timeInterval.targetAtLeast} to ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                              if (widget.timeInterval.targetType ==
                                  TargetType.atLeast)
                                Text(
                                  'Target: at least ${widget.timeInterval.targetAtLeast} ${widget.timeInterval.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                              if (widget.timeInterval.targetType ==
                                  TargetType.atMost)
                                Text(
                                  'Target: at most ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                            ],
                          ),
                        ),
                        // if (widget.timeInterval.targetType == TargetType.about)
                        //   Text(
                        //       'Target: about ${widget.timeInterval.targetAtLeast} to ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                        //       style: TextStyle(color: labelColor)),
                        // if (widget.timeInterval.targetType ==
                        //     TargetType.atLeast)
                        //   Text(
                        //     'Target: at least ${widget.timeInterval.targetAtLeast} ${widget.timeInterval.unit}',
                        //     style: TextStyle(color: labelColor),
                        //   ),
                        // if (widget.timeInterval.targetType == TargetType.atMost)
                        //   Text(
                        //     'Target: at most ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                        //     style: TextStyle(color: labelColor),
                        //   ),
                        // if (widget.timeInterval.howMuchHasBeenDone != 0)
                        //   Text(
                        //     'Has been done: ${widget.timeInterval.howMuchHasBeenDone} ${widget.timeInterval.unit}',
                        //     style: TextStyle(color: labelColor),
                        //   ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_outlined, color: labelColor),
                      onSelected: (String result) {
                        if (result == 'option1') {
                          widget.onTimeIntervalEdit(widget.timeInterval);
                        } else if (result == 'option2') {
                          widget.onTimeIntervalDelete(widget.timeInterval);
                        } else if (result == 'option3') {
                          widget.onTimeIntervalToggleComplete(
                              widget.timeInterval);
                        } else if (result == 'option4') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddOrEditTimeIntervalPage(
                                    timeInterval: widget.timeInterval)),
                          );
                        } else if (result == 'option5') {
                          setState(() => _isExpanded = !_isExpanded);
                          _saveIsExpanded();
                          //widget.onSubtasksDisplayChanged;
                        } else if (result == 'option6') {
                          setState(() => _isExpanded = !_isExpanded);
                          _saveIsExpanded();
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
                                    ? const Text('Hide sub-tasks')
                                    : const Text('Show sub-tasks'),
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
                                  ? const Text('Hide target infor')
                                  : const Text('Show target infor'),
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
                                  ? const Text('Mark as incompleted')
                                  : const Text('Mark as completed'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option4',
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty),
                              SizedBox(width: 8),
                              Text('Add time interval'),
                            ],
                          ),
                        ),
                        // const PopupMenuItem<String>(
                        //   value: 'option6',
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.timelapse_outlined),
                        //       SizedBox(width: 8),
                        //       Text('Focus right now?'),
                        //     ],
                        //   ),
                        // ),
                        const PopupMenuItem<String>(
                          value: 'option1',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Edit this time interval'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option2',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined),
                              SizedBox(width: 8),
                              Text('Delete this time interval'),
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
                          'Has been done: ${widget.timeInterval.howMuchHasBeenDone} ${widget.timeInterval.unit}',
                        ),
                        onPressed: () =>
                            widget.onHasBeenDoneUpdate(widget.timeInterval),
                      ),
                    ),
                  ),
                  if (_isExpanded &&
                      widget.timeInterval.taskWithSubtasksId != null)
                    ...widget.timeInterval.subtasks.map(
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
                              //setState(() {
                              //_isLoading = false;
                              widget.timeInterval.subtasks.remove(subtask);
                              //});
                              widget.onSubtasksChanged(widget.timeInterval);
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
