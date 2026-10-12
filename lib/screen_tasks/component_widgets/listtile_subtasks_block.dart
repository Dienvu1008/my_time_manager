import 'package:flutter/material.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_schedule.dart';

/// Khối chỉnh sửa danh sách công việc con của một task.
///
/// Mỗi công việc con có thể:
///  - đánh dấu hoàn thành,
///  - sửa tiêu đề + bật/tắt đo lường (target/đơn vị),
///  - xóa,
///  - và (khi đang sửa một task đã lưu) được LẬP KẾ HOẠCH riêng.
///
/// [parentTask] chỉ dùng để dựng ô lập kế hoạch cho subtask (màu/vị trí...).
/// [allowScheduling] = true khi task đã tồn tại trong DB (mới lập kế hoạch được).
class SubtasksListTile extends StatefulWidget {
  final List<Subtask> subtasks;
  final Task parentTask;
  final bool allowScheduling;
  final VoidCallback onChanged;

  const SubtasksListTile({
    super.key,
    required this.subtasks,
    required this.parentTask,
    required this.onChanged,
    this.allowScheduling = false,
  });

  @override
  State<SubtasksListTile> createState() => _SubtasksListTileState();
}

class _SubtasksListTileState extends State<SubtasksListTile> {
  Future<void> _editSubtask(Subtask subtask) async {
    final result = await _showSubtaskDialog(initial: subtask);
    if (result != null) {
      setState(() {
        subtask.title = result.title;
        subtask.isMeasurable = result.isMeasurable;
        subtask.targetType = result.targetType;
        subtask.targetAtLeast = result.targetAtLeast;
        subtask.targetAtMost = result.targetAtMost;
        subtask.unit = result.unit;
      });
      widget.onChanged();
    }
  }

  Future<void> _addSubtask() async {
    final result = await _showSubtaskDialog();
    if (result != null) {
      setState(() => widget.subtasks.add(result));
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.subtasks.map((subtask) {
          return Column(
            children: [
              CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                value: subtask.isCompleted,
                onChanged: (value) {
                  setState(() => subtask.isCompleted = value ?? false);
                  widget.onChanged();
                },
                title: GestureDetector(
                  onTap: () => _editSubtask(subtask),
                  child: Text(
                    subtask.title,
                    style: TextStyle(
                      decoration: subtask.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                subtitle: subtask.isMeasurable
                    ? Text(_measurableLabel(subtask))
                    : null,
                secondary: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.allowScheduling)
                      IconButton(
                        icon: const Icon(Icons.event_note_outlined),
                        tooltip: 'Lập kế hoạch cho công việc con',
                        onPressed: () => _scheduleSubtask(subtask),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => widget.subtasks.remove(subtask));
                        widget.onChanged();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 12.0),
        Row(children: [
          ElevatedButton(
            onPressed: _addSubtask,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 4),
                Text('Thêm công việc con'),
              ],
            ),
          )
        ]),
        const SizedBox(height: 8.0),
        const Divider(height: 4),
      ],
    );
  }

  String _measurableLabel(Subtask s) {
    switch (s.targetType) {
      case TargetType.atLeast:
        return 'Ít nhất ${s.targetAtLeast} ${s.unit}';
      case TargetType.atMost:
        return 'Nhiều nhất ${s.targetAtMost} ${s.unit}';
      case TargetType.about:
        return 'Khoảng ${s.targetAtLeast}–${s.targetAtMost} ${s.unit}';
    }
  }

  void _scheduleSubtask(Subtask subtask) {
    // Mở ô lập kế hoạch (dùng lại ScheduleListTile logic thông qua bottomsheet).
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: _SubtaskScheduleLauncher(
          task: widget.parentTask,
          subtask: subtask,
        ),
      ),
    );
  }

  /// Hộp thoại thêm/sửa một công việc con (tiêu đề + tùy chọn đo lường).
  Future<Subtask?> _showSubtaskDialog({Subtask? initial}) {
    final titleController = TextEditingController(text: initial?.title ?? '');
    final unitController = TextEditingController(text: initial?.unit ?? '');
    final atLeastController = TextEditingController(
        text: (initial != null && initial.targetAtLeast.isFinite)
            ? initial.targetAtLeast.toString()
            : '');
    final atMostController = TextEditingController(
        text: (initial != null && initial.targetAtMost.isFinite)
            ? initial.targetAtMost.toString()
            : '');
    bool isMeasurable = initial?.isMeasurable ?? false;
    TargetType targetType = initial?.targetType ?? TargetType.about;

    return showDialog<Subtask>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(initial == null
                  ? 'Thêm công việc con'
                  : 'Sửa công việc con'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đo lường'),
                      value: isMeasurable,
                      onChanged: (v) => setDialogState(() => isMeasurable = v),
                    ),
                    if (isMeasurable) ...[
                      DropdownButtonFormField<TargetType>(
                        value: targetType,
                        decoration:
                            const InputDecoration(labelText: 'Kiểu mục tiêu'),
                        items: const [
                          DropdownMenuItem(
                              value: TargetType.about, child: Text('Khoảng')),
                          DropdownMenuItem(
                              value: TargetType.atLeast,
                              child: Text('Ít nhất')),
                          DropdownMenuItem(
                              value: TargetType.atMost,
                              child: Text('Nhiều nhất')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => targetType = v ?? targetType),
                      ),
                      TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Đơn vị'),
                      ),
                      if (targetType == TargetType.atLeast ||
                          targetType == TargetType.about)
                        TextField(
                          controller: atLeastController,
                          decoration:
                              const InputDecoration(labelText: 'Tối thiểu'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      if (targetType == TargetType.atMost ||
                          targetType == TargetType.about)
                        TextField(
                          controller: atMostController,
                          decoration:
                              const InputDecoration(labelText: 'Tối đa'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final atLeast = isMeasurable
                        ? (double.tryParse(atLeastController.text) ??
                            double.negativeInfinity)
                        : double.negativeInfinity;
                    final atMost = isMeasurable
                        ? (double.tryParse(atMostController.text) ??
                            double.infinity)
                        : double.infinity;
                    Navigator.pop(
                      context,
                      Subtask(
                        id: initial?.id,
                        title: title,
                        isCompleted: initial?.isCompleted ?? false,
                        isMeasurable: isMeasurable,
                        targetType: targetType,
                        targetAtLeast: atLeast,
                        targetAtMost: atMost,
                        unit: unitController.text.trim(),
                        howMuchHasBeenDone: initial?.howMuchHasBeenDone ?? 0.0,
                      ),
                    );
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Widget nhỏ chỉ để dựng [ScheduleListTile] cho một subtask bên trong
/// bottomsheet (ScheduleListTile tự mở bottomsheet của nó khi nhấn).
class _SubtaskScheduleLauncher extends StatelessWidget {
  final Task task;
  final Subtask subtask;
  const _SubtaskScheduleLauncher({required this.task, required this.subtask});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Lập kế hoạch: ${subtask.title}',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ScheduleListTile(task: task, subtask: subtask),
      ],
    );
  }
}
