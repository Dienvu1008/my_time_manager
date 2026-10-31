// Giờ yên lặng (Phase R, plan D7).
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/model_reminder_rule.dart';
import 'wall_clock_resolver.dart';

/// Khung giờ yên lặng theo wall-clock (phút trong ngày, có thể vắt qua nửa
/// đêm). Mốc nhắc rơi vào `[start, end)` được dời tới `end` kế tiếp.
/// `start == end` → không hoạt động.
class QuietHours {
  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  const QuietHours({
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
  });

  /// Tắt (mặc định 22:00–07:00 nhưng không áp dụng).
  static const QuietHours off =
      QuietHours(enabled: false, startMinutes: 1320, endMinutes: 420);

  bool get isActive => enabled && startMinutes != endMinutes;

  /// [minuteOfDay] có nằm trong `[start, end)` không.
  bool contains(int minuteOfDay) {
    if (!isActive) return false;
    if (startMinutes < endMinutes) {
      return minuteOfDay >= startMinutes && minuteOfDay < endMinutes;
    }
    return minuteOfDay >= startMinutes || minuteOfDay < endMinutes;
  }

  /// Dời [fireUtc] tới wall-clock `end` kế tiếp (phân giải an toàn DST) nếu nó
  /// rơi vào giờ yên lặng; ngược lại trả về nguyên giá trị.
  DateTime adjust(DateTime fireUtc, tz.Location loc) {
    if (!isActive) return fireUtc;
    final wc = wallClockOf(fireUtc, loc);
    final minuteOfDay = wc.hour * 60 + wc.minute;
    if (!contains(minuteOfDay)) return fireUtc;
    var date = DateTime.utc(wc.year, wc.month, wc.day);
    if (minuteOfDay >= endMinutes) date = date.add(const Duration(days: 1));
    final target = WallClock(
        date.year, date.month, date.day, endMinutes ~/ 60, endMinutes % 60);
    final shifted = resolveWallClock(loc, target);
    return shifted.isAfter(fireUtc) ? shifted : fireUtc;
  }

  @override
  bool operator ==(Object other) =>
      other is QuietHours &&
      other.enabled == enabled &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(enabled, startMinutes, endMinutes);

  @override
  String toString() =>
      'QuietHours(enabled: $enabled, $startMinutes-$endMinutes)';
}
