import '../../application/reminders/notification_scheduler.dart';
import '../../screen_focus_timer/data/notification_service.dart';

/// Adapter thật của [NotificationScheduler] (Phase R, D9/D12): ủy quyền cho
/// [NotificationService.instance] (flutter_local_notifications).
class LocalNotificationScheduler implements NotificationScheduler {
  const LocalNotificationScheduler();

  NotificationService get _service => NotificationService.instance;

  @override
  Future<void> schedule(ScheduledReminder reminder) =>
      _service.scheduleReminderAt(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        fireAtUtc: reminder.fireAt,
      );

  @override
  Future<void> cancel(int id) => _service.cancelReminder(id);

  /// Bản ném lỗi (khác [NotificationService.cancelAll] của legacy) để
  /// coordinator đếm lỗi (D8).
  @override
  Future<void> cancelAll() => _service.cancelAllReminders();

  @override
  Future<ReminderPermission> permissionStatus() =>
      _service.reminderPermissionStatus();

  @override
  Future<bool> exactAlarmsAllowed() => _service.canScheduleExactReminders();

  /// Chỉ gọi khi người dùng chủ động (nút "Allow"): xin quyền thông báo rồi
  /// quyền báo thức chính xác (Android 12+ có thể mở màn Cài đặt).
  @override
  Future<bool> requestPermission() async {
    await _service.requestNotificationPermission();
    await _service.requestExactAlarmPermission();
    return (await _service.reminderPermissionStatus()) !=
        ReminderPermission.denied;
  }
}
