// Id thông báo tất định cho nhắc nhở (Phase R, plan D3).
import 'dart:convert';

import '../../domain/models/model_calendar_event.dart';
import '../../domain/models/model_reminder_rule.dart';
import '../../domain/models/model_time_interval.dart';

/// Các mốc nhắc phổ biến (phút trước) — dùng để dọn thông báo cũ khi hủy.
const List<int> kCommonReminderMinutes = [
  0,
  5,
  10,
  15,
  30,
  60,
  120,
  1440,
  2880,
  10080,
];

/// Id của mốc nhắc legacy (TimeInterval + số phút trước). PHẢI giống hệt công
/// thức cũ của `NotificationService` để đường cũ/mới ghi đè và hủy lẫn nhau.
int legacyIntervalReminderId(String intervalId, int minutes) =>
    ('$intervalId#$minutes').hashCode & 0x7fffffff;

/// FNV-1a 32-bit trên UTF-8 của [key], thu về 31-bit dương. 0 được đổi thành
/// 1 (id 0 dành cho thông báo `show` của focus timer). Ổn định qua các phiên
/// bản Dart (khác `String.hashCode`).
int stableReminderId(String key) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(key)) {
    h ^= b;
    // h * 0x01000193 mod 2^32, tách (h << 24) + h * 0x193 để không vượt 2^53
    // (an toàn cả khi biên dịch sang JS).
    h = ((((h & 0xff) << 24) + h * 0x193) & 0xffffffff);
  }
  final id = h & 0x7fffffff;
  return id == 0 ? 1 : id;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Hậu tố lần xuất hiện `@YYYYMMDDTHHMM` (wall-clock bắt đầu lần xuất hiện).
String _occurrenceSuffix(WallClock? occurrence) {
  if (occurrence == null) return '';
  final o = occurrence;
  return '@${o.year.toString().padLeft(4, '0')}${_two(o.month)}${_two(o.day)}'
      'T${_two(o.hour)}${_two(o.minute)}';
}

/// Khóa của mốc nhắc legacy TimeInterval (chỉ để nhận diện; id dùng
/// [legacyIntervalReminderId]).
String legacyIntervalKey(String intervalId, int minutes) =>
    '${ReminderEntityType.timeInterval}:$intervalId#$minutes';

/// Khóa nhắc popup override của CalendarEvent.
String calendarOverrideKey(String eventId, int minutes,
        {WallClock? occurrence}) =>
    '${ReminderEntityType.calendarEvent}:$eventId#$minutes'
    '${_occurrenceSuffix(occurrence)}';

/// Khóa nhắc của một rule tường minh.
String ruleKey(String ruleId, {WallClock? occurrence}) =>
    'rule:$ruleId${_occurrenceSuffix(occurrence)}';

/// Mọi id có thể đã được đặt cho [interval]: mốc hiện tại ∪ mốc phổ biến
/// (cùng tập với `cancelForTimeInterval`).
Set<int> legacyCandidateIds(TimeInterval interval) => {
      for (final m in {...interval.reminderMinutesBefore, ...kCommonReminderMinutes})
        legacyIntervalReminderId(interval.id, m),
    };

/// Mọi id (không lặp) có thể đã được đặt cho popup override của [event].
Set<int> calendarCandidateIds(CalendarEvent event) {
  final minutes = <int>{
    for (final o in event.reminders.overrides)
      if (o.method == ReminderMethod.popup) o.minutes,
    ...kCommonReminderMinutes,
  };
  return {
    for (final m in minutes) stableReminderId(calendarOverrideKey(event.id, m)),
  };
}

/// Id (không lặp) của một rule tường minh.
Set<int> ruleCandidateIds(ReminderRule rule) => {stableReminderId(ruleKey(rule.id))};
