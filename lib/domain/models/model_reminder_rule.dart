// Model ReminderRule (Phase R — Reminders & Alarms, plan D1)
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Thời điểm "đồng hồ treo tường" (năm/tháng/ngày/giờ/phút) KHÔNG kèm múi
/// giờ. Lưu dạng TEXT `'YYYY-MM-DDTHH:MM'`; được hiểu theo múi giờ cục bộ khi
/// lập lịch (nên 09:00 vẫn là 09:00 sau khi đổi múi giờ / DST).
class WallClock {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  const WallClock(this.year, this.month, this.day,
      [this.hour = 0, this.minute = 0]);

  /// Lấy các trường cục bộ (local fields) của [dateTime].
  factory WallClock.fromDateTime(DateTime dateTime) {
    final d = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return WallClock(d.year, d.month, d.day, d.hour, d.minute);
  }

  static final RegExp _pattern =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$');

  /// Parse dạng `'YYYY-MM-DDTHH:MM'`; trả về null nếu null / sai định dạng /
  /// ngày-giờ không hợp lệ (vd. 2026-02-30, 24:00).
  static WallClock? tryParse(String? value) {
    if (value == null) return null;
    final m = _pattern.firstMatch(value.trim());
    if (m == null) return null;
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    final h = int.parse(m.group(4)!);
    final mi = int.parse(m.group(5)!);
    if (mo < 1 || mo > 12 || d < 1 || h > 23 || mi > 59) return null;
    // Kiểm tra ngày tồn tại trong tháng (DateTime tự tràn nếu không hợp lệ).
    final probe = DateTime(y, mo, d);
    if (probe.month != mo || probe.day != d) return null;
    return WallClock(y, mo, d, h, mi);
  }

  /// `'YYYY-MM-DDTHH:MM'` (đệm 0).
  String toStorage() {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-${two(month)}-${two(day)}'
        'T${two(hour)}:${two(minute)}';
  }

  /// DateTime cục bộ tương ứng (không gắn múi giờ).
  DateTime toLocalDateTime() => DateTime(year, month, day, hour, minute);

  @override
  bool operator ==(Object other) =>
      other is WallClock &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(year, month, day, hour, minute);

  @override
  String toString() => 'WallClock(${toStorage()})';
}

/// Loại thực thể mà một rule nhắc gắn vào. Dùng String (không phải enum) để
/// bản ghi do phiên bản sau ghi ra (vd. 'habit') vẫn đọc được; planner bỏ qua
/// loại không biết.
class ReminderEntityType {
  ReminderEntityType._();

  static const String timeInterval = 'timeInterval';
  static const String calendarEvent = 'calendarEvent';
  static const String task = 'task';
}

/// Kiểu rule: lệch so với mốc của thực thể ([offset]) hoặc thời điểm tuyệt
/// đối ([absolute]).
enum ReminderRuleKind {
  offset,
  absolute;

  /// Parse tên lưu trữ; không biết / null → [offset].
  static ReminderRuleKind fromName(String? name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return offset;
  }
}

/// Mức ưu tiên của thông báo (lưu INTEGER 0/1).
enum ReminderPriority {
  normal,
  high;

  /// Parse giá trị lưu trữ; ngoài phạm vi / null → [normal].
  static ReminderPriority fromValue(Object? value) {
    final i = value is int ? value : int.tryParse('${value ?? ''}');
    if (i == null || i < 0 || i >= values.length) return normal;
    return values[i];
  }
}

/// Một rule nhắc tường minh (bảng `reminder_rules`, schema v16).
///
/// - [ReminderRuleKind.offset]: [offsetMinutes] (≥ 0) phút trước mốc thực thể.
/// - [ReminderRuleKind.absolute]: nhắc tại [absoluteAt] (wall-clock cục bộ).
///
/// `deviceId` do DAO gắn khi insert.
class ReminderRule extends Equatable {
  final String id;
  final String entityType;
  final String entityId;
  final ReminderRuleKind kind;
  final int? offsetMinutes;
  final WallClock? absoluteAt;
  final bool enabled;
  final ReminderPriority priority;
  final DateTime createdAt;
  final DateTime updateTimeStamp;
  final String? deviceId;

  ReminderRule({
    String? id,
    required this.entityType,
    required this.entityId,
    this.kind = ReminderRuleKind.offset,
    this.offsetMinutes,
    this.absoluteAt,
    this.enabled = true,
    this.priority = ReminderPriority.normal,
    DateTime? createdAt,
    DateTime? updateTimeStamp,
    this.deviceId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  /// Rule nhắc [minutes] phút trước mốc của thực thể.
  factory ReminderRule.offset({
    String? id,
    required String entityType,
    required String entityId,
    required int minutes,
    bool enabled = true,
    ReminderPriority priority = ReminderPriority.normal,
  }) =>
      ReminderRule(
        id: id,
        entityType: entityType,
        entityId: entityId,
        kind: ReminderRuleKind.offset,
        offsetMinutes: minutes,
        enabled: enabled,
        priority: priority,
      );

  /// Rule nhắc tại thời điểm tuyệt đối [at].
  factory ReminderRule.absolute({
    String? id,
    required String entityType,
    required String entityId,
    required WallClock at,
    bool enabled = true,
    ReminderPriority priority = ReminderPriority.normal,
  }) =>
      ReminderRule(
        id: id,
        entityType: entityType,
        entityId: entityId,
        kind: ReminderRuleKind.absolute,
        absoluteAt: at,
        enabled: enabled,
        priority: priority,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'kind': kind.name,
      'offsetMinutes': offsetMinutes,
      'absoluteAt': absoluteAt?.toStorage(),
      'enabled': enabled ? 1 : 0,
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  /// Chịu được null / kind không biết / priority ngoài phạm vi.
  factory ReminderRule.fromMap(Map<String, dynamic> map) {
    DateTime? date(Object? raw) =>
        raw == null ? null : DateTime.tryParse(raw.toString());
    final offsetRaw = map['offsetMinutes'];
    final enabledRaw = map['enabled'];
    return ReminderRule(
      id: map['id'] as String?,
      entityType: (map['entityType'] as String?) ?? '',
      entityId: (map['entityId'] as String?) ?? '',
      kind: ReminderRuleKind.fromName(map['kind'] as String?),
      offsetMinutes:
          offsetRaw is int ? offsetRaw : int.tryParse('${offsetRaw ?? ''}'),
      absoluteAt: WallClock.tryParse(map['absoluteAt'] as String?),
      enabled: enabledRaw == null
          ? true
          : (enabledRaw == 1 || enabledRaw == true || enabledRaw == '1'),
      priority: ReminderPriority.fromValue(map['priority']),
      createdAt: date(map['createdAt']),
      updateTimeStamp: date(map['updateTimeStamp']),
      deviceId: map['deviceId'] as String?,
    );
  }

  ReminderRule copyWith({
    String? entityType,
    String? entityId,
    ReminderRuleKind? kind,
    int? offsetMinutes,
    WallClock? absoluteAt,
    bool? enabled,
    ReminderPriority? priority,
    DateTime? updateTimeStamp,
  }) {
    return ReminderRule(
      id: id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      kind: kind ?? this.kind,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      absoluteAt: absoluteAt ?? this.absoluteAt,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
      deviceId: deviceId,
    );
  }

  @override
  String toString() => 'ReminderRule(id: $id, $entityType:$entityId, '
      '${kind.name}, offset: $offsetMinutes, at: ${absoluteAt?.toStorage()}, '
      'enabled: $enabled, priority: ${priority.name})';

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        kind,
        offsetMinutes,
        absoluteAt,
        enabled,
        priority,
        createdAt,
        updateTimeStamp,
        deviceId,
      ];
}
