import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';
import 'package:my_time_manager/utils/utils.dart';

class MeasurableTaskCard extends StatefulWidget {
  final MeasurableTask measurableTask;
  final Function(MeasurableTask) onMeasurableTaskEdit;
  final Function(MeasurableTask) onMeasurableTaskDelete;
  final Function(MeasurableTask) onMeasurableTaskToggleComplete;
  final Function(MeasurableTask) onHasBeenDoneUpdate;
  final bool Function(MeasurableTask) isMeasurableTaskCardExpanded;
  final Function(MeasurableTask) onMeasurableTaskCardExpanded;

  const MeasurableTaskCard({
    Key? key,
    required this.measurableTask,
    required this.onMeasurableTaskEdit,
    required this.onMeasurableTaskDelete,
    required this.onMeasurableTaskToggleComplete,
    required this.onHasBeenDoneUpdate,
    required this.isMeasurableTaskCardExpanded,
    required this.onMeasurableTaskCardExpanded,
  }) : super(key: key);

  @override
  _MeasurableTaskCardState createState() => _MeasurableTaskCardState();
}

class _MeasurableTaskCardState extends State<MeasurableTaskCard> {
  // static Color contrastColor(Color color) {
  //   final brightness = ThemeData.estimateBrightnessForColor(color);
  //   switch (brightness) {
  //     case Brightness.dark:
  //       return Colors.white;
  //     case Brightness.light:
  //       return Colors.black;
  //   }
  // }

  // Phần chương trình này sẽ gây ra việc nháy màn hình khi mở rộng TaskListCard hoặc chuyển từ widget khác về overview

  // bool _isExpanded = true;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadIsExpanded();
  // }

  // void _loadIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final isExpanded =
  //       prefs.getBool('isExpanded_${widget.measurableTask.id}') ?? true;
  //   if (mounted) {
  //     setState(() {
  //       _isExpanded = isExpanded;
  //     });
  //   }
  // }

  // void _saveIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setBool('isExpanded_${widget.measurableTask.id}', _isExpanded);
  // }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
                    //dense: true,
                    //contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                    // title: Text(
                    //   widget.measurableTask.title,
                    //   style: TextStyle(
                    //     color: labelColor,
                    //     decoration: widget.measurableTask.isCompleted
                    //         ? TextDecoration.lineThrough
                    //         : null,
                    //   ),
                    // ),
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.measurableTask.isImportant)
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
                            widget.measurableTask.title,
                            style: TextStyle(
                              color: labelColor,
                              decoration: widget.measurableTask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ]),
                    // subtitle: widget.measurableTask.description.isNotEmpty
                    //     ? Text(
                    //         widget.measurableTask.description,
                    //         style: TextStyle(color: labelColor),
                    //       )
                    //     : null,
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
                                ShowOrSetTimeIntervalsBottomSheet(
                              title: widget.measurableTask.title,
                              color: widget.measurableTask.color,
                              description: widget.measurableTask.description,
                              location: widget.measurableTask.location,
                              targetAtLeast:
                                  widget.measurableTask.targetAtLeast,
                              targetAtMost: widget.measurableTask.targetAtMost,
                              targetType: widget.measurableTask.targetType,
                              unit: widget.measurableTask.unit,
                              subtasks: [],
                              measurableTaskId: widget.measurableTask.id,
                              isSetTimeIntervalPage: true,
                            ),
                          );
                        } else if (result == 'option6') {
                          widget.onMeasurableTaskCardExpanded(
                              widget.measurableTask);
                          // setState(() => _isExpanded = !_isExpanded);
                          // _saveIsExpanded();
                        } else if (result == 'planned') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (BuildContext context) =>
                                ShowOrSetTimeIntervalsBottomSheet(
                              title: widget.measurableTask.title,
                              color: widget.measurableTask.color,
                              description: widget.measurableTask.description,
                              location: widget.measurableTask.location,
                              targetAtLeast:
                                  widget.measurableTask.targetAtLeast,
                              targetAtMost: widget.measurableTask.targetAtMost,
                              targetType: widget.measurableTask.targetType,
                              unit: widget.measurableTask.unit,
                              subtasks: [],
                              measurableTaskId: widget.measurableTask.id,
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
                          value: 'option6',
                          child: Row(
                            children: [
                              Icon(//_isExpanded
                                  widget.isMeasurableTaskCardExpanded(
                                          widget.measurableTask)
                                      ? Icons.chevron_right
                                      : Icons.expand_more),
                              const SizedBox(width: 8),
                              //_isExpanded
                              widget.isMeasurableTaskCardExpanded(
                                      widget.measurableTask)
                                  ? Expanded(child: Text(localizations!.hideTargetInfor))
                                  : Expanded(child: Text(localizations!.showTargetInfor),)
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
                  if (widget
                      .isMeasurableTaskCardExpanded(widget.measurableTask))
                    ListTile(
                      dense: true,
                      //contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                      //contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.measurableTask.targetType ==
                              TargetType.about)
                            Text(
                              '${localizations!.targetAbout} ${widget.measurableTask.targetAtLeast} ${localizations.to} ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                              style: TextStyle(color: labelColor),
                            ),
                          if (widget.measurableTask.targetType ==
                              TargetType.atLeast)
                            Text(
                              '${localizations!.targetAtLeast} ${widget.measurableTask.targetAtLeast} ${widget.measurableTask.unit}',
                              style: TextStyle(color: labelColor),
                            ),
                          if (widget.measurableTask.targetType ==
                              TargetType.atMost)
                            Text(
                              '${localizations!.targetAtMost} ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                              style: TextStyle(color: labelColor),
                            ),
                        ],
                      ),
                    ),
                  // Visibility(
                  //   visible: widget.isMeasurableTaskCardExpanded(
                  //       widget.measurableTask), //_isExpanded,
                  //   child: Column(
                  //     children: [
                  //       // if (widget
                  //       //         .measurableTask.description.isNotEmpty ||
                  //       //     widget.measurableTask.description != '')
                  //       //   Text(
                  //       //     widget.measurableTask.description,
                  //       //     style: TextStyle(color: labelColor),
                  //       //   ),
                  //       if (widget.measurableTask.targetType ==
                  //           TargetType.about)
                  //         Text(
                  //           'Target: about ${widget.measurableTask.targetAtLeast} to ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                  //           style: TextStyle(color: labelColor),
                  //         ),
                  //       if (widget.measurableTask.targetType ==
                  //           TargetType.atLeast)
                  //         Text(
                  //           'Target: at least ${widget.measurableTask.targetAtLeast} ${widget.measurableTask.unit}',
                  //           style: TextStyle(color: labelColor),
                  //         ),
                  //       if (widget.measurableTask.targetType ==
                  //           TargetType.atMost)
                  //         Text(
                  //           'Target: at most ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                  //           style: TextStyle(color: labelColor),
                  //         ),
                  //     ],
                  //   ),
                  // ),

                  // Visibility(
                  //   visible: widget.isMeasurableTaskCardExpanded(
                  //       widget.measurableTask), //_isExpanded,
                  //   child: ListTile(
                  //     title: ActionChip(
                  //       label: Text(
                  //         'Has been done: ${widget.measurableTask.howMuchHasBeenDone} ${widget.measurableTask.unit}',
                  //       ),
                  //       onPressed: () =>
                  //           widget.onHasBeenDoneUpdate(widget.measurableTask),
                  //     ),
                  //   ),
                  // )
                  if (widget
                      .isMeasurableTaskCardExpanded(widget.measurableTask))
                    ListTile(
                      dense: true,
                      //contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                      //contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                      title: ActionChip(
                        label: Text(
                          '${localizations!.hasBeenDone} ${widget.measurableTask.howMuchHasBeenDone} ${widget.measurableTask.unit}',
                        ),

                        // Text(
                        //   localizations!.hasBeenDone ${widget.measurableTask.howMuchHasBeenDone} ${widget.measurableTask.unit},
                        // ),
                        onPressed: () =>
                            widget.onHasBeenDoneUpdate(widget.measurableTask),
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
