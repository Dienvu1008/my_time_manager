import '../../application/reminder_scheduler.dart';
import '../../domain/models/model_time_interval.dart';
import '../../screen_focus_timer/data/notification_service.dart';

/// [ReminderScheduler] thật dùng trong production: ủy thác cho
/// [NotificationService] (flutter_local_notifications + timezone).
///
/// Tất cả lỗi được nuốt bên trong NotificationService (debugPrint); class này
/// không cần xử lý thêm.
class NotificationReminderScheduler implements ReminderScheduler {
  const NotificationReminderScheduler();

  @override
  Future<void> schedule(TimeInterval interval) =>
      NotificationService.instance.scheduleForTimeInterval(interval);

  @override
  Future<void> scheduleAll(List<TimeInterval> intervals) async {
    for (final ti in intervals) {
      await NotificationService.instance.scheduleForTimeInterval(ti);
    }
  }

  @override
  Future<void> cancel(TimeInterval interval) =>
      NotificationService.instance.cancelForTimeInterval(interval);

  @override
  Future<void> rescheduleAll(List<TimeInterval> intervals) async {
    await NotificationService.instance.cancelAll();
    for (final ti in intervals) {
      await NotificationService.instance.scheduleForTimeInterval(ti);
    }
  }
}
