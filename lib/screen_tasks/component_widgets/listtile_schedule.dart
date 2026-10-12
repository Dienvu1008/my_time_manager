import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';

/// Ô "Lập kế hoạch" cho một task (hoặc một công việc con của task).
///
/// Truyền [task]; nếu lập kế hoạch cho một công việc con cụ thể thì truyền
/// thêm [subtask]. Tiêu đề/màu/mục tiêu... được lấy từ subtask nếu có, ngược
/// lại từ task cha.
class ScheduleListTile extends StatelessWidget {
  final Task task;
  final Subtask? subtask;

  const ScheduleListTile({super.key, required this.task, this.subtask});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final title = subtask?.title ?? task.title;
    final bool measurable = subtask?.isMeasurable ?? task.isMeasurable;
    final TargetType targetType = subtask?.isMeasurable == true
        ? subtask!.targetType
        : task.targetType;
    final double targetAtLeast = subtask?.isMeasurable == true
        ? subtask!.targetAtLeast
        : task.targetAtLeast;
    final double targetAtMost = subtask?.isMeasurable == true
        ? subtask!.targetAtMost
        : task.targetAtMost;
    final String unit =
        subtask?.isMeasurable == true ? subtask!.unit : task.unit;

    ShowOrSetTimeIntervalsBottomSheet buildSheet(bool isSetPage) {
      return ShowOrSetTimeIntervalsBottomSheet(
        title: title,
        color: task.color,
        description: task.description,
        location: task.location,
        targetType: measurable ? targetType : TargetType.about,
        targetAtLeast: measurable ? targetAtLeast : double.negativeInfinity,
        targetAtMost: measurable ? targetAtMost : double.infinity,
        unit: measurable ? unit : '',
        subtasks: subtask == null ? task.subtasks : const [],
        taskId: task.id,
        subtaskId: subtask?.id,
        isSetTimeIntervalPage: isSetPage,
      );
    }

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
                  SafeArea(child: buildSheet(false)),
            );
          },
          trailing: TextButton(
            child: Text(localizations.schedule),
            onPressed: () => {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (BuildContext context) =>
                    SafeArea(child: buildSheet(true)),
              )
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
