import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_set_time_intervals.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_time_intervals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeasurableTaskCard extends StatefulWidget {
  final MeasurableTask measurableTask;
  final Function(MeasurableTask) onMeasurableTaskEdit;
  final Function(MeasurableTask) onMeasurableTaskDelete;
  final Function(MeasurableTask) onMeasurableTaskToggleComplete;
  final Function(MeasurableTask) onHasBeenDoneUpdate;

  const MeasurableTaskCard({
    Key? key,
    required this.measurableTask,
    required this.onMeasurableTaskEdit,
    required this.onMeasurableTaskDelete,
    required this.onMeasurableTaskToggleComplete,
    required this.onHasBeenDoneUpdate,
  }) : super(key: key);

  @override
  _MeasurableTaskCardState createState() => _MeasurableTaskCardState();
}

class _MeasurableTaskCardState extends State<MeasurableTaskCard> {
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
        prefs.getBool('isExpanded_${widget.measurableTask.id}') ?? true;
    if (mounted) {
      setState(() {
        _isExpanded = isExpanded;
      });
    }
  }

  void _saveIsExpanded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isExpanded_${widget.measurableTask.id}', _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final measurableTaskColor = widget.measurableTask.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: measurableTaskColor)
        : ColorScheme.light(primary: measurableTaskColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);

    return Card(
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onMeasurableTaskEdit(widget.measurableTask),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      widget.measurableTask.title,
                      style: TextStyle(
                        color: labelColor,
                        decoration: widget.measurableTask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.measurableTask.description.isNotEmpty ||
                            widget.measurableTask.description != '')
                          Text(
                            widget.measurableTask.description,
                            style: TextStyle(color: labelColor),
                          ),
                        Visibility(
                          visible: _isExpanded,
                          child: Column(
                            children: [
                              // if (widget
                              //         .measurableTask.description.isNotEmpty ||
                              //     widget.measurableTask.description != '')
                              //   Text(
                              //     widget.measurableTask.description,
                              //     style: TextStyle(color: labelColor),
                              //   ),
                              if (widget.measurableTask.targetType ==
                                  TargetType.about)
                                Text(
                                  'Target: about ${widget.measurableTask.targetAtLeast} to ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                              if (widget.measurableTask.targetType ==
                                  TargetType.atLeast)
                                Text(
                                  'Target: at least ${widget.measurableTask.targetAtLeast} ${widget.measurableTask.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                              if (widget.measurableTask.targetType ==
                                  TargetType.atMost)
                                Text(
                                  'Target: at most ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                                  style: TextStyle(color: labelColor),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: labelColor),
                      onSelected: (String result) {
                        if (result == 'option1') {
                          widget.onMeasurableTaskEdit(widget.measurableTask);
                        } else if (result == 'option2') {
                          widget.onMeasurableTaskDelete(widget.measurableTask);
                        } else if (result == 'option3') {
                          widget.onMeasurableTaskToggleComplete(
                              widget.measurableTask);
                        } else if (result == 'option4') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                SetTimeIntervalBottomSheet(
                              measurableTaskId: widget.measurableTask.id,
                            ),
                          );
                        } else if (result == 'option6') {
                          setState(() => _isExpanded = !_isExpanded);
                          _saveIsExpanded();
                        } else if (result == 'planned') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                ShowTimeIntervalsBottomSheet(
                              measurableTaskId: widget.measurableTask.id,
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
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
                              Icon(widget.measurableTask.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.measurableTask.isCompleted
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
                          value: 'option5',
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
                  Visibility(
                    visible: _isExpanded,
                    child: ListTile(
                      title: ActionChip(
                        label: Text(
                          'Has been done: ${widget.measurableTask.howMuchHasBeenDone} ${widget.measurableTask.unit}',
                        ),
                        onPressed: () =>
                            widget.onHasBeenDoneUpdate(widget.measurableTask),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
