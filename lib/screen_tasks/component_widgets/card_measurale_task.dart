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
  final bool isProVersion;

  const MeasurableTaskCard({
    Key? key,
    required this.measurableTask,
    required this.onMeasurableTaskEdit,
    required this.onMeasurableTaskDelete,
    required this.onMeasurableTaskToggleComplete,
    required this.onHasBeenDoneUpdate,
    required this.isMeasurableTaskCardExpanded,
    required this.onMeasurableTaskCardExpanded,
    required this.isProVersion,
  }) : super(key: key);

  @override
  _MeasurableTaskCardState createState() => _MeasurableTaskCardState();
}

class _MeasurableTaskCardState extends State<MeasurableTaskCard> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final measurableTaskColor = widget.measurableTask.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: measurableTaskColor)
        : ColorScheme.light(primary: measurableTaskColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onMeasurableTaskEdit(widget.measurableTask),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(right:0, left: 8),
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.measurableTask.isImportant)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                localizations!.important,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          Text(
                            widget.measurableTask.title,
                            style: widget.measurableTask.isCompleted
                                ? textTheme.labelLarge!.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: labelColor)
                                : textTheme.labelLarge!
                                    .copyWith(color: labelColor),
                          ),
                        ]),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: labelColor),
                      onSelected: (String result) {
                        if (result == 'edit') {
                          widget.onMeasurableTaskEdit(widget.measurableTask);
                        } else if (result == 'delete') {
                          widget.onMeasurableTaskDelete(widget.measurableTask);
                        } else if (result == 'completion') {
                          widget.onMeasurableTaskToggleComplete(
                              widget.measurableTask);
                        } else if (result == 'schedule') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            enableDrag: true,
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
                        } else if (result == 'expand') {
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
                          if (widget.isProVersion) {
                            showComingSoonDialog(context);
                          } else {
                            showWillBeAvaiableOnProVersionDialog(context);
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'expand',
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
                                  ? Expanded(
                                      child:
                                          Text(localizations!.hideTargetInfor))
                                  : Expanded(
                                      child:
                                          Text(localizations!.showTargetInfor),
                                    )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'completion',
                          child: Row(
                            children: [
                              Icon(widget.measurableTask.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.measurableTask.isCompleted
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
                  if (widget
                      .isMeasurableTaskCardExpanded(widget.measurableTask))
                    ListTile(
                      dense: true,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.measurableTask.targetType ==
                              TargetType.about)
                            Text(
                              '${localizations!.targetAbout} ${widget.measurableTask.targetAtLeast} ${localizations.to} ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                              style: textTheme.labelMedium!
                                  .copyWith(color: labelColor),
                            ),
                          if (widget.measurableTask.targetType ==
                              TargetType.atLeast)
                            Text(
                              '${localizations!.targetAtLeast} ${widget.measurableTask.targetAtLeast} ${widget.measurableTask.unit}',
                              style: textTheme.labelMedium!
                                  .copyWith(color: labelColor),
                            ),
                          if (widget.measurableTask.targetType ==
                              TargetType.atMost)
                            Text(
                              '${localizations!.targetAtMost} ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                              style: textTheme.labelMedium!
                                  .copyWith(color: labelColor),
                            ),
                          Center(
                            child: ActionChip(
                              label: Text(
                                '${localizations!.hasBeenDone} ${widget.measurableTask.howMuchHasBeenDone} ${widget.measurableTask.unit}',
                              ),
                              onPressed: () => widget
                                  .onHasBeenDoneUpdate(widget.measurableTask),
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
