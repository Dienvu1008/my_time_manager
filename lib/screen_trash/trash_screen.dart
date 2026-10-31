import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app.dart';
import '../domain/repositories/trash_repository.dart';
import 'model_trashed_item.dart';

/// Màn hình Thùng rác: hiển thị các mục đã xóa (TaskList và 3 loại task),
/// cho phép khôi phục hoặc xóa vĩnh viễn từng mục, xóa sạch toàn bộ, và cấu hình
/// số ngày tự động giữ trước khi xóa vĩnh viễn.
///
/// Được nhúng trong content area của Home (bọc Expanded để khớp layout). Số ngày
/// giữ đọc/ghi qua [AppBloc] (SharedPreferences).
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late final TrashRepository _trashRepository = context.read<TrashRepository>();
  late Future<List<TrashedItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _itemsFuture = _trashRepository.getTrashedItems();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _itemsFuture;
  }

  IconData _iconFor(TrashedItemType type) {
    switch (type) {
      case TrashedItemType.taskList:
        return Icons.folder_outlined;
      case TrashedItemType.task:
        return Icons.check_circle_outline;
      case TrashedItemType.calendarEvent:
        return Icons.event_outlined;
      case TrashedItemType.goal:
        return Icons.flag_outlined;
    }
  }

  Future<void> _restore(TrashedItem item) async {
    await _trashRepository.restore(item);
    if (mounted) {
      _showSnack('Đã khôi phục "${item.title}".');
      await _refresh();
    }
  }

  Future<void> _permanentlyDelete(TrashedItem item) async {
    final confirmed = await _confirm(
      title: 'Xóa vĩnh viễn',
      content: 'Xóa vĩnh viễn "${item.title}"? Hành động này không thể hoàn tác.',
    );
    if (confirmed != true) return;

    await _trashRepository.permanentlyDelete(item);
    if (mounted) {
      _showSnack('Đã xóa vĩnh viễn "${item.title}".');
      await _refresh();
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await _confirm(
      title: 'Dọn sạch thùng rác',
      content:
          'Xóa vĩnh viễn tất cả mục trong thùng rác? Hành động này không thể hoàn tác.',
    );
    if (confirmed != true) return;
    await _trashRepository.emptyTrash();
    if (mounted) {
      _showSnack('Đã dọn sạch thùng rác.');
      await _refresh();
    }
  }

  Future<bool?> _confirm(
      {required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AppBar(
            title: const Text('Thùng rác',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Dọn sạch thùng rác',
                onPressed: _emptyTrash,
              ),
            ],
          ),
          _retentionSetting(context),
          const Divider(height: 1),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  /// Ô cấu hình số ngày giữ rác, đọc/ghi qua AppBloc.
  Widget _retentionSetting(BuildContext context) {
    final days = context.select((AppBloc b) => b.state.trashRetentionDays);
    const options = [7, 14, 30, 60, 90];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.auto_delete_outlined),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Tự động xóa vĩnh viễn sau'),
          ),
          DropdownButton<int>(
            value: options.contains(days) ? days : 30,
            items: options
                .map((d) => DropdownMenuItem(value: d, child: Text('$d ngày')))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<AppBloc>().add(ChangeTrashRetentionDays(value));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _list() {
    return FutureBuilder<List<TrashedItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải thùng rác: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Thùng rác trống.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(_iconFor(item.type)),
                title: Text(
                  item.title.isEmpty ? '(Không có tiêu đề)' : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                    '${item.type.label} · Đã xóa ${_formatDate(item.deletedAt)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Khôi phục',
                      onPressed: () => _restore(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      tooltip: 'Xóa vĩnh viễn',
                      onPressed: () => _permanentlyDelete(item),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Định dạng ngày đơn giản dd/MM/yyyy.
  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}
