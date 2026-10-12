import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/task_repository.dart';
import '../bloc/pomodoro_config.dart';
import '../../domain/models/model_focus_session.dart';

/// Bottom sheet cho phép chọn một task để focus.
///
/// Trả về [SelectedTask] đã chọn (hoặc null nếu người dùng chọn "Không gắn task"
/// / đóng sheet).
class TaskPickerSheet extends StatefulWidget {
  const TaskPickerSheet({super.key});

  /// Mở sheet và trả về lựa chọn. Kết quả:
  /// - SelectedTask: đã chọn một task.
  /// - null: đóng mà không chọn.
  static Future<SelectedTask?> show(BuildContext context) {
    return showModalBottomSheet<SelectedTask?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const TaskPickerSheet(),
    );
  }

  @override
  State<TaskPickerSheet> createState() => _TaskPickerSheetState();
}

class _TaskPickerSheetState extends State<TaskPickerSheet> {
  late final TaskRepository _taskRepository = context.read<TaskRepository>();
  late Future<List<SelectedTask>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadAllTasks();
  }

  /// Nạp danh sách task chưa hoàn thành (đã hợp nhất về một loại Task).
  Future<List<SelectedTask>> _loadAllTasks() async {
    final tasks = await _taskRepository.getTasks();
    return [
      for (final t in tasks.where((e) => !e.isCompleted))
        SelectedTask(
          type: FocusTaskType.task,
          id: t.id,
          title: t.title,
          isMeasurable: t.isMeasurable,
          hasSubtasks: t.hasSubtasks,
        ),
    ];
  }

  IconData _iconFor(SelectedTask task) {
    if (task.isMeasurable) return Icons.trending_up;
    if (task.hasSubtasks) return Icons.checklist;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Chọn công việc để tập trung',
                  style: theme.textTheme.titleLarge),
            ),
            // Tùy chọn "không gắn task".
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Không gắn công việc'),
              subtitle: const Text('Chỉ tập trung, không theo dõi theo task'),
              onTap: () => Navigator.of(context).pop(null),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<SelectedTask>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Lỗi tải danh sách: ${snapshot.error}'));
                  }
                  final tasks = snapshot.data ?? [];
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Chưa có công việc nào chưa hoàn thành.\n'
                          'Hãy tạo công việc ở màn hình Công việc.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        leading: Icon(_iconFor(task)),
                        title: Text(task.title),
                        onTap: () => Navigator.of(context).pop(task),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
