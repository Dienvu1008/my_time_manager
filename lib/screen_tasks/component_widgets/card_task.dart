import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/screen_focus_timer/bloc/pomodoro_config.dart';
import 'package:my_time_manager/screen_focus_timer/data/model_focus_session.dart';
import 'package:my_time_manager/screen_focus_timer/view/pomodoro_screen.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/attached_notes_view.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:my_time_manager/utils/utils.dart';

/// Thẻ hiển thị MỘT task hợp nhất. Tự thích ứng theo nội dung task:
///  - task thường: chỉ tiêu đề + menu.
///  - task đo lường (isMeasurable): thêm dòng mục tiêu + chip cập nhật tiến độ.
///  - task có công việc con: thêm danh sách công việc con (mở/thu gọn).
class TaskCard extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;
  final Function(Task) onTaskToggleComplete;

  /// Lưu trữ task (ẩn khỏi màn chính, không xóa). Tùy chọn.
  final Function(Task)? onTaskArchive;

  /// Cập nhật tiến độ (howMuchHasBeenDone) cho task đo lường.
  final Function(Task)? onHasBeenDoneUpdate;

  /// Được gọi khi trạng thái công việc con thay đổi (để lưu lại).
  final Function(Task)? onSubtasksChanged;

  final bool isProVersion;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTaskToggleComplete,
    this.onTaskArchive,
    this.onHasBeenDoneUpdate,
    this.onSubtasksChanged,
    required this.isProVersion,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

  String _targetLabel(AppLocalizations l) {
    final t = widget.task;
    switch (t.targetType) {
      case TargetType.atLeast:
        return '${l.targetAtLeast} ${t.targetAtLeast} ${t.unit}';
      case TargetType.atMost:
        return '${l.targetAtMost} ${t.targetAtMost} ${t.unit}';
      case TargetType.about:
        return '${l.targetAbout} ${t.targetAtLeast} ${l.to} ${t.targetAtMost} ${t.unit}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final task = widget.task;
    final taskColor = task.color;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Kiểu hiển thị thẻ được đọc trực tiếp từ AppBloc (Pattern B) nên không cần
    // truyền qua constructor. Mặc định là filled nếu AppBloc chưa sẵn sàng.
    final cardStyle = context.watch<AppBloc>().state.taskCardStyle;
    final bool leadingBar = cardStyle == TaskCardStyle.leadingColorBar;

    // Màu nền thẻ + màu chữ tùy theo kiểu:
    //  - filled: nền = primaryContainer của màu task, chữ tương phản với nền đó.
    //  - leadingColorBar: nền = surface trung tính, chữ = onSurface, màu task
    //    chỉ xuất hiện ở dải dọc bên trái.
    final Color backgroundColor;
    final Color labelColor;
    if (leadingBar) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      labelColor = theme.colorScheme.onSurface;
    } else {
      final myColorScheme = theme.brightness == Brightness.dark
          ? ColorScheme.dark(primary: taskColor)
          : ColorScheme.light(primary: taskColor);
      backgroundColor = myColorScheme.primaryContainer;
      labelColor = contrastColor(backgroundColor);
    }

    final content = Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTaskEdit(task),
                  // Thay ListTile bằng Padding + Row tự-co-theo-nội-dung. ListTile
                  // áp một chiều cao tối thiểu cố định; khi title xếp nhiều dòng
                  // (nhãn "Quan trọng" + tiêu đề + mục tiêu + ghi chú) và bị bọc
                  // trong IntrinsicHeight ở kiểu leadingColorBar, nội dung vượt
                  // quá chiều cao đó -> RenderFlex overflow vài pixel ở đáy.
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.isImportant)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      localizations.important,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                Text(
                                  task.title,
                                  style: task.isCompleted
                                      ? textTheme.labelLarge!.copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: labelColor)
                                      : textTheme.labelLarge!
                                          .copyWith(color: labelColor),
                                ),
                                if (task.isMeasurable)
                                  Text(
                                    _targetLabel(localizations),
                                    style: textTheme.labelMedium!
                                        .copyWith(color: labelColor),
                                  ),
                                if (task.noteIds.isNotEmpty)
                                  AttachedNotesView(
                                    noteIds: task.noteIds,
                                    color: labelColor,
                                    textStyle: textTheme.labelMedium!
                                        .copyWith(color: labelColor),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        _buildMenu(context, localizations, labelColor),
                      ],
                    ),
                  ),
                ),
              ),
              // Nút mở/thu gọn khi có công việc con.
              if (task.hasSubtasks)
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: labelColor,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
            ],
          ),

          // Chip cập nhật tiến độ cho task đo lường.
          if (task.isMeasurable && widget.onHasBeenDoneUpdate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: ActionChip(
                  label: Text(
                    '${localizations.hasBeenDone} ${task.howMuchHasBeenDone} ${task.unit}',
                    style: textTheme.labelMedium!.copyWith(color: labelColor),
                  ),
                  onPressed: () => widget.onHasBeenDoneUpdate!(task),
                ),
              ),
            ),

          // Danh sách công việc con (khi mở).
          if (task.hasSubtasks && _expanded)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Column(
                children: task.subtasks.map((subtask) {
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: subtask.isCompleted,
                    activeColor: labelColor,
                    onChanged: (value) {
                      setState(() => subtask.isCompleted = value ?? false);
                      widget.onSubtasksChanged?.call(task);
                    },
                    title: Text(
                      subtask.title,
                      style: textTheme.labelMedium!.copyWith(
                        color: labelColor,
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );

    // Kiểu filled: nền thẻ mang màu task (như trước).
    if (!leadingBar) {
      return Card(
        color: backgroundColor,
        child: content,
      );
    }

    // Kiểu leadingColorBar: nền trung tính + dải màu dọc bên trái (bo góc trái
    // theo thẻ). Dùng ClipRRect để dải màu không tràn ra ngoài bo góc của Card.
    return Card(
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: taskColor),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(
      BuildContext context, AppLocalizations localizations, Color labelColor) {
    final task = widget.task;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: labelColor),
      onSelected: (String result) {
        if (result == 'edit_task') {
          widget.onTaskEdit(task);
        } else if (result == 'delete_task') {
          widget.onTaskDelete(task);
        } else if (result == 'archive_task') {
          widget.onTaskArchive?.call(task);
        } else if (result == 'mark_completion') {
          widget.onTaskToggleComplete(task);
        } else if (result == 'schedule' || result == 'planned') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (BuildContext context) => ShowOrSetTimeIntervalsBottomSheet(
              title: task.title,
              color: task.color,
              description: task.description,
              location: task.location,
              targetType: task.isMeasurable ? task.targetType : TargetType.about,
              targetAtLeast:
                  task.isMeasurable ? task.targetAtLeast : double.negativeInfinity,
              targetAtMost:
                  task.isMeasurable ? task.targetAtMost : double.infinity,
              unit: task.isMeasurable ? task.unit : '',
              subtasks: task.subtasks,
              taskId: task.id,
              isSetTimeIntervalPage: result == 'schedule',
            ),
          );
        } else if (result == 'focus_timer') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PomodoroPage(
                initialTask: SelectedTask(
                  type: FocusTaskType.task,
                  id: task.id,
                  title: task.title,
                  isMeasurable: task.isMeasurable,
                  hasSubtasks: task.hasSubtasks,
                ),
              ),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'mark_completion',
          child: Row(
            children: [
              Icon(task.isCompleted
                  ? Icons.check_box
                  : Icons.check_box_outline_blank),
              const SizedBox(width: 8),
              Expanded(
                child: Text(task.isCompleted
                    ? localizations.markAsIncompleted
                    : localizations.markAsCompleted),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'schedule',
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(localizations.schedule)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'planned',
          child: Row(
            children: [
              const Icon(Icons.event_note_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(localizations.planned)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'focus_timer',
          child: Row(
            children: [
              const Icon(Icons.timelapse_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(localizations.focusRightNow)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit_task',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(localizations.editTask)),
            ],
          ),
        ),
        if (widget.onTaskArchive != null)
          PopupMenuItem<String>(
            value: 'archive_task',
            child: Row(
              children: [
                const Icon(Icons.archive_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(localizations.archive)),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'delete_task',
          child: Row(
            children: [
              const Icon(Icons.delete_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(localizations.deleteTask)),
            ],
          ),
        ),
      ],
    );
  }
}
