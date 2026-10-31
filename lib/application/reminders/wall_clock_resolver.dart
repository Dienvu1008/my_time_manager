// Phân giải wall-clock → instant theo múi giờ (Phase R, plan D5 / R-b).
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/model_reminder_rule.dart';

const int _dayMs = 86400000;
const int _minuteMs = 60000;

/// Wall-clock (dạng ms "naive UTC") của [instantMs] trong [loc].
int _wallMs(tz.Location loc, int instantMs) =>
    instantMs + loc.timeZone(instantMs).offset;

/// Trả về instant (UTC) ứng với wall-clock [wc] trong [loc].
///
/// - Nhiều instant hợp lệ (giờ lặp khi lùi DST) → instant sớm nhất.
/// - Không có instant (giờ bị nhảy khi tiến DST) → instant đầu tiên có
///   wall-clock ≥ yêu cầu (tức thời điểm chuyển), chính xác tới phút.
DateTime resolveWallClock(tz.Location loc, WallClock wc) {
  final naive =
      DateTime.utc(wc.year, wc.month, wc.day, wc.hour, wc.minute)
          .millisecondsSinceEpoch;
  final offsetBefore = loc.timeZone(naive - _dayMs).offset;
  final offsetAfter = loc.timeZone(naive + _dayMs).offset;
  final offsets = {offsetBefore, loc.timeZone(naive).offset, offsetAfter};

  int? best;
  for (final off in offsets) {
    final instant = naive - off;
    if (_wallMs(loc, instant) == naive && (best == null || instant < best)) {
      best = instant;
    }
  }
  if (best != null) return DateTime.fromMillisecondsSinceEpoch(best, isUtc: true);

  // Khoảng trống DST: tìm nhị phân (theo phút) instant đầu tiên có wall ≥ naive.
  var lo = (naive - offsetAfter) ~/ _minuteMs;
  var hi = (naive - offsetBefore) ~/ _minuteMs;
  if (lo > hi) {
    final t = lo;
    lo = hi;
    hi = t;
  }
  if (_wallMs(loc, hi * _minuteMs) < naive) {
    // Không kỳ vọng xảy ra; dùng offset trước chuyển đổi.
    return DateTime.fromMillisecondsSinceEpoch(naive - offsetBefore,
        isUtc: true);
  }
  while (lo < hi) {
    final mid = lo + ((hi - lo) ~/ 2);
    if (_wallMs(loc, mid * _minuteMs) >= naive) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(lo * _minuteMs, isUtc: true);
}

/// Wall-clock của instant [utc] trong [loc].
WallClock wallClockOf(DateTime utc, tz.Location loc) {
  final t = tz.TZDateTime.from(utc, loc);
  return WallClock(t.year, t.month, t.day, t.hour, t.minute);
}
