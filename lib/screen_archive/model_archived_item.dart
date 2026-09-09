/// Loại đối tượng có thể được lưu trữ (archive).
enum ArchivedItemType {
  taskList,
  task,
  calendarEvent;

  /// Nhãn hiển thị tiếng Việt.
  String get label {
    switch (this) {
      case ArchivedItemType.taskList:
        return 'Danh sách';
      case ArchivedItemType.task:
        return 'Công việc';
      case ArchivedItemType.calendarEvent:
        return 'Sự kiện';
    }
  }

  /// Tên bảng SQLite tương ứng.
  String get table {
    switch (this) {
      case ArchivedItemType.taskList:
        return 'tasklists';
      case ArchivedItemType.task:
        return 'tasks';
      case ArchivedItemType.calendarEvent:
        return 'calendar_events';
    }
  }
}

/// Một mục đã được lưu trữ — chỉ giữ những thông tin cần để hiển thị và thao tác
/// (bỏ lưu trữ), không cần nạp đầy đủ model gốc.
class ArchivedItem {
  const ArchivedItem({
    required this.type,
    required this.id,
    required this.title,
    required this.archivedAt,
  });

  final ArchivedItemType type;
  final String id;
  final String title;

  /// Thời điểm được đưa vào lưu trữ.
  final DateTime archivedAt;
}
