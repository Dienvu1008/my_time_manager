import '../domain/models/model_time_interval.dart';

/// Ranh giới application cho việc lên lịch nhắc nhở OS. Tách phần phối hợp
/// side-effect (thông báo) ra khỏi tầng persistence, để:
///   - `DatabaseManager` thuần SQL, không phụ thuộc platform channel.
///   - Dễ stub/mock trong test mà không cần platform binding.
///   - Chuẩn bị cho Phase R (ReminderRule / ReminderCoordinator).
///
/// Chỉ [TimeInterval] cần interface này ngay bây giờ; CalendarEvent và Habit
/// sẽ mở rộng interface (hoặc thêm interface riêng) khi Phase R được triển khai.
abstract class ReminderScheduler {
  /// Lên lịch (hoặc lên lịch lại) các mốc nhắc cho [interval]. No-op nếu
  /// interval không có mốc nhắc hoặc platform không hỗ trợ.
  Future<void> schedule(TimeInterval interval);

  /// Hủy mọi mốc nhắc đã đặt cho [interval]. No-op nếu không có.
  Future<void> cancel(TimeInterval interval);

  /// Hủy tất cả rồi lên lịch lại cho tất cả interval hiện có. Dùng khi người
  /// dùng bật lại tính năng nhắc sau khi tắt.
  Future<void> rescheduleAll(List<TimeInterval> intervals);
}

/// Implementation no-op dùng cho môi trường không cần nhắc (test, desktop).
/// Không throw, không cần Flutter binding.
class NoOpReminderScheduler implements ReminderScheduler {
  const NoOpReminderScheduler();
  @override
  Future<void> schedule(TimeInterval interval) async {}
  @override
  Future<void> cancel(TimeInterval interval) async {}
  @override
  Future<void> rescheduleAll(List<TimeInterval> intervals) async {}
}
