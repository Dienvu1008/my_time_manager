// Một mốc nhắc đã lập kế hoạch (Phase R, plan item 2).
import '../../domain/models/model_reminder_rule.dart';

/// Nguồn sinh mốc nhắc.
enum ReminderSource {
  /// Trường legacy (TimeInterval.reminderMinutesBefore, CalendarEvent popup
  /// overrides).
  legacy,

  /// Rule tường minh (bảng reminder_rules).
  rule,
}

/// Mốc nhắc mong muốn do planner sinh ra.
class PlannedReminder {
  final int id;
  final String key;
  final String entityType;
  final String entityId;

  /// Thời điểm bắn (UTC), đã áp giờ yên lặng.
  final DateTime fireAt;

  /// Mốc của thực thể (UTC) với nhắc lệch; null với nhắc tuyệt đối.
  final DateTime? anchorAt;

  /// Số phút trước mốc (nhắc lệch); null với nhắc tuyệt đối.
  final int? offsetMinutes;
  final ReminderPriority priority;
  final String title;
  final String body;
  final ReminderSource source;
  final bool shiftedByQuietHours;

  const PlannedReminder({
    required this.id,
    required this.key,
    required this.entityType,
    required this.entityId,
    required this.fireAt,
    this.anchorAt,
    this.offsetMinutes,
    this.priority = ReminderPriority.normal,
    required this.title,
    required this.body,
    this.source = ReminderSource.legacy,
    this.shiftedByQuietHours = false,
  });

  PlannedReminder copyWith({DateTime? fireAt, bool? shiftedByQuietHours}) =>
      PlannedReminder(
        id: id,
        key: key,
        entityType: entityType,
        entityId: entityId,
        fireAt: fireAt ?? this.fireAt,
        anchorAt: anchorAt,
        offsetMinutes: offsetMinutes,
        priority: priority,
        title: title,
        body: body,
        source: source,
        shiftedByQuietHours: shiftedByQuietHours ?? this.shiftedByQuietHours,
      );

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.fireAt == fireAt &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, fireAt, title, body);

  @override
  String toString() =>
      'PlannedReminder($id, $key, ${fireAt.toIso8601String()}, $title)';
}
