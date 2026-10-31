/// Loại đối tượng có thể nằm trong thùng rác.
enum TrashedItemType {
  taskList,
  task,
  calendarEvent,
  goal;

  /// Nhãn hiển thị tiếng Việt.
  String get label {
    switch (this) {
      case TrashedItemType.taskList:
        return 'Danh sách';
      case TrashedItemType.task:
        return 'Công việc';
      case TrashedItemType.calendarEvent:
        return 'Sự kiện';
      case TrashedItemType.goal:
        return 'Mục tiêu';
    }
  }

  /// Tên bảng SQLite tương ứng.
  String get table {
    switch (this) {
      case TrashedItemType.taskList:
        return 'tasklists';
      case TrashedItemType.task:
        return 'tasks';
      case TrashedItemType.calendarEvent:
        return 'calendar_events';
      case TrashedItemType.goal:
        return 'goals';
    }
  }
}

/// Một mục trong thùng rác — chỉ giữ những thông tin cần để hiển thị và thao tác
/// (khôi phục / xóa vĩnh viễn), không cần nạp đầy đủ model gốc.
class TrashedItem {
  const TrashedItem({
    required this.type,
    required this.id,
    required this.title,
    required this.deletedAt,
  });

  final TrashedItemType type;
  final String id;
  final String title;

  /// Thời điểm bị chuyển vào thùng rác.
  final DateTime deletedAt;
}
