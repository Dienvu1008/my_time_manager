// Cổng (port) lên lịch thông báo OS (Phase R, plan item 3 / D12). Adapter
// thật nằm ở lib/data/notifications/.

/// Một thông báo cần đặt.
class ScheduledReminder {
  final int id;

  /// Thời điểm bắn (UTC).
  final DateTime fireAt;
  final String title;
  final String body;
  final bool important;

  const ScheduledReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    this.important = false,
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.fireAt == fireAt &&
      other.title == title &&
      other.body == body &&
      other.important == important;

  @override
  int get hashCode => Object.hash(id, fireAt, title, body, important);

  @override
  String toString() =>
      'ScheduledReminder($id, ${fireAt.toIso8601String()}, $title)';
}

/// Trạng thái quyền hiển thị thông báo.
enum ReminderPermission { granted, denied, notApplicable }

abstract class NotificationScheduler {
  Future<void> schedule(ScheduledReminder reminder);
  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<ReminderPermission> permissionStatus();

  /// false = nền tảng chưa cho phép báo thức chính xác (Android 12+), nhắc sẽ
  /// được đặt ở chế độ không chính xác. true trên nền tảng không áp dụng.
  Future<bool> exactAlarmsAllowed();

  /// Chỉ gọi khi người dùng chủ động yêu cầu: xin quyền thông báo và quyền báo
  /// thức chính xác. Trả về true nếu đã có quyền thông báo.
  Future<bool> requestPermission();
}

/// Không làm gì (test, nền tảng không hỗ trợ).
class NoOpNotificationScheduler implements NotificationScheduler {
  const NoOpNotificationScheduler();
  @override
  Future<void> schedule(ScheduledReminder reminder) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<ReminderPermission> permissionStatus() async =>
      ReminderPermission.notApplicable;
  @override
  Future<bool> exactAlarmsAllowed() async => true;
  @override
  Future<bool> requestPermission() async => true;
}
