import 'package:flutter/material.dart';

import '../data/database/database_manager.dart';
import 'model_archived_item.dart';

/// Màn hình Lưu trữ: hiển thị các mục đã được lưu trữ (TaskList và Task),
/// cho phép bỏ lưu trữ (đưa trở lại màn chính) hoặc chuyển vào thùng rác.
///
/// Được nhúng trong content area của Home (bọc Expanded để khớp layout), giống
/// cách TrashScreen hoạt động. Khác với thùng rác, lưu trữ KHÔNG có thời hạn tự
/// động xóa — mục nằm trong lưu trữ đến khi người dùng chủ động xử lý.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final DatabaseManager _db = DatabaseManager();
  late Future<List<ArchivedItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _itemsFuture = _db.archivedItems();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _itemsFuture;
  }

  IconData _iconFor(ArchivedItemType type) {
    switch (type) {
      case ArchivedItemType.taskList:
        return Icons.folder_outlined;
      case ArchivedItemType.task:
        return Icons.check_circle_outline;
      case ArchivedItemType.calendarEvent:
        return Icons.event_outlined;
    }
  }

  Future<void> _unarchive(ArchivedItem item) async {
    switch (item.type) {
      case ArchivedItemType.taskList:
        await _db.unarchiveTaskList(item.id);
        break;
      case ArchivedItemType.task:
        await _db.unarchiveTask(item.id);
        break;
      case ArchivedItemType.calendarEvent:
        await _db.unarchiveCalendarEvent(item.id);
        break;
    }
    if (mounted) {
      _showSnack('Đã bỏ lưu trữ "${item.title}".');
      await _refresh();
    }
  }

  /// Chuyển một mục từ lưu trữ vào thùng rác (soft-delete). Bỏ trạng thái lưu
  /// trữ trước, rồi đánh dấu đã xóa, để nó xuất hiện đúng trong thùng rác.
  Future<void> _moveToTrash(ArchivedItem item) async {
    final confirmed = await _confirm(
      title: 'Chuyển vào thùng rác',
      content: 'Chuyển "${item.title}" vào thùng rác?',
    );
    if (confirmed != true) return;

    switch (item.type) {
      case ArchivedItemType.taskList:
        await _db.unarchiveTaskList(item.id);
        await _db.softDeleteTaskList(item.id);
        break;
      case ArchivedItemType.task:
        await _db.unarchiveTask(item.id);
        await _db.softDeleteTask(item.id);
        break;
      case ArchivedItemType.calendarEvent:
        await _db.unarchiveCalendarEvent(item.id);
        await _db.softDeleteCalendarEvent(item.id);
        break;
    }
    if (mounted) {
      _showSnack('Đã chuyển "${item.title}" vào thùng rác.');
      await _refresh();
    }
  }

  Future<bool?> _confirm({required String title, required String content}) {
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
            title: const Text('Lưu trữ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _list() {
    return FutureBuilder<List<ArchivedItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải lưu trữ: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa có mục nào được lưu trữ.',
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
                    '${item.type.label} · Đã lưu trữ ${_formatDate(item.archivedAt)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      tooltip: 'Bỏ lưu trữ',
                      onPressed: () => _unarchive(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Chuyển vào thùng rác',
                      onPressed: () => _moveToTrash(item),
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
