import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';

class ScheduleListTile extends StatelessWidget {
  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;
  final String title;
  final Color color;

  final String description;
  final String location;
  final TargetType targetType;
  final double targetAtLeast;
  final double targetAtMost;
  final String unit;
  final List<Subtask> subtasks;

  ScheduleListTile(
      {this.taskId,
      this.measurableTaskId,
      this.taskWithSubtasksId,
      required this.title,
      required this.color,
      required this.description,
      required this.location,
      required this.targetType,
      required this.targetAtLeast,
      required this.targetAtMost,
      required this.subtasks,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.only(left: 0.0, right: 4.0),
            child: Icon(Icons.event_note_outlined),
          ),
          title: Text(localizations!.planned),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (BuildContext context) =>
                  SafeArea(child: ShowOrSetTimeIntervalsBottomSheet(
                title: title,
                color: color,
                description: description,
                location: location,
                targetType: targetType,
                targetAtLeast: targetAtLeast,
                targetAtMost: targetAtMost,
                unit: unit,
                subtasks: subtasks,
                taskId: taskId,
                measurableTaskId: measurableTaskId,
                taskWithSubtasksId: taskWithSubtasksId,
                isSetTimeIntervalPage: false,
              ),
            ));
          },
          trailing: TextButton(
            child: Text(localizations.schedule),
            onPressed: () => {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (BuildContext context) =>
                    SafeArea(child : ShowOrSetTimeIntervalsBottomSheet(
                  title: title,
                  color: color,
                  description: description,
                  location: location,
                  targetType: targetType,
                  targetAtLeast: targetAtLeast,
                  targetAtMost: targetAtMost,
                  unit: unit,
                  subtasks: subtasks,
                  taskId: taskId,
                  measurableTaskId: measurableTaskId,
                  taskWithSubtasksId: taskWithSubtasksId,
                  isSetTimeIntervalPage: true,
                ),
              ),)
            },
          ),
        ),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}
