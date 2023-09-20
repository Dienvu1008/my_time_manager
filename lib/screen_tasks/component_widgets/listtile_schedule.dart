import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_set_time_intervals.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_time_intervals.dart';

class ScheduleListTile extends StatelessWidget {
  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;

  ScheduleListTile(
      {this.taskId, this.measurableTaskId, this.taskWithSubtasksId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.only(left: 0.0, right: 4.0),
            child: Icon(Icons.hourglass_empty_outlined),
          ),
          title: Text('Schedule'),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (BuildContext context) => SetTimeIntervalBottomSheet(
                  taskId: taskId,
                  measurableTaskId: measurableTaskId,
                  taskWithSubtasksId: taskWithSubtasksId),
            );
          },
          trailing: ElevatedButton(
            child: Text('Planned'),
            onPressed: () => {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (BuildContext context) => ShowTimeIntervalsBottomSheet(
                    taskId: taskId,
                    measurableTaskId: measurableTaskId,
                    taskWithSubtasksId: taskWithSubtasksId),
              ),
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
