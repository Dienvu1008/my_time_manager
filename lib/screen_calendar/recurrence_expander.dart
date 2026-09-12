import '../data/models/model_calendar_event.dart';

/// Khai triển (expand) một [CalendarEvent] lặp lại thành các lần xuất hiện
/// (instances) CỤ THỂ nằm trong một cửa sổ thời gian, CHỈ để hiển thị trên
/// lịch. Không ghi gì vào DB — khác với `RecurrenceService` (dành cho
/// TimeInterval, vốn lưu nhiều dòng thật).
///
/// Vì sao expand khi hiển thị thay vì lưu sẵn: sự kiện lặp có thể vô hạn
/// (không COUNT/UNTIL); lưu tất cả là bất khả thi. Ta chỉ sinh những lần rơi
/// vào khoảng đang xem.
///
/// Hỗ trợ tập con thực dụng của RRULE (RFC 5545) đủ cho các mẫu mà trình
/// thêm/sửa sự kiện của app tạo ra, cùng vài mở rộng phổ biến:
///   - FREQ = DAILY | WEEKLY | MONTHLY | YEARLY (bắt buộc)
///   - INTERVAL = n (mặc định 1)
///   - COUNT = n  (tổng số lần, kể cả lần gốc)
///   - UNTIL = ...  (mốc kết thúc, bao gồm)
///   - BYDAY = MO,TU,... (chỉ áp dụng cho WEEKLY)
/// Cùng EXDATE (loại trừ ngày) và RDATE (thêm ngày rời) ở cấp danh sách
/// [CalendarEvent.recurrence].
///
/// Các mẫu phức tạp hơn (BYMONTHDAY, BYSETPOS, WKST...) không được xử lý; khi
/// gặp, hàm bỏ qua phần không hiểu và vẫn sinh theo FREQ/INTERVAL để không mất
/// sự kiện.

/// Số lần lặp tối đa sinh ra cho MỘT sự kiện trong một cửa sổ — chặn an toàn
/// tránh vòng lặp thoát khỏi tầm kiểm soát với rule lạ.
const int _kMaxInstances = 1000;

/// Trả về danh sách các instance của [event] có phần thời gian giao với
/// [windowStart, windowEnd]. Nếu [event] không lặp, trả về chính nó (khi giao
/// với cửa sổ) — nên có thể gọi cho mọi sự kiện.
///
/// Mỗi instance là một [CalendarEvent] mới với [start]/[end] đã dịch tới lần
/// xuất hiện tương ứng, mang [recurringEventId] = id sự kiện gốc và [id] riêng
/// (dạng `id#epochMillis`) để không trùng khi hiển thị.
List<CalendarEvent> expandRecurringEvent(
  CalendarEvent event,
  DateTime windowStart,
  DateTime windowEnd,
) {
  if (!event.isRecurring) {
    if (_overlapsWindow(event.start.effective, event.end.effective,
        windowStart, windowEnd)) {
      return [event];
    }
    return const [];
  }

  final rule = _RRule.parse(event.recurrence);
  final baseStart = event.start.effective;
  final baseEnd = event.end.effective;
  // Độ dài sự kiện, giữ nguyên qua mọi lần lặp.
  final duration = baseEnd.difference(baseStart);

  final exDates = _collectExDates(event.recurrence);

  final results = <CalendarEvent>[];
  final seen = <int>{};

  void addInstanceAt(DateTime startDt) {
    final key = startDt.millisecondsSinceEpoch;
    if (!seen.add(key)) return;
    if (_isExcluded(startDt, exDates)) return;
    final endDt = startDt.add(duration);
    // Chỉ giữ lần giao với cửa sổ hiển thị.
    if (!_overlapsWindow(startDt, endDt, windowStart, windowEnd)) return;
    results.add(_instanceAt(event, startDt, endDt));
  }

  if (rule == null || rule.freq == _Freq.none) {
    // Không đọc được RRULE -> ít nhất hiển thị lần gốc nếu giao cửa sổ.
    addInstanceAt(baseStart);
  } else {
    var generated = 0;
    var period = 0;
    while (generated < _kMaxInstances) {
      // Mỗi lần lặp tính TỪ mốc gốc [baseStart] (không dồn sai số qua từng
      // bước) — đảm bảo MONTHLY neo theo ngày gốc (31/1 -> 28/2 -> 31/3).
      final occurrence = rule.occurrenceFromBase(baseStart, period);

      // Dừng theo UNTIL.
      if (rule.until != null && occurrence.isAfter(rule.until!)) break;
      // Dừng theo COUNT.
      if (rule.count != null && generated >= rule.count!) break;

      if (rule.freq == _Freq.weekly && rule.byDays.isNotEmpty) {
        // WEEKLY + BYDAY: trong mỗi "tuần lặp", sinh cho từng thứ được liệt kê.
        for (final weekday in rule.byDays) {
          final dayInWeek = _shiftToWeekday(occurrence, weekday);
          if (rule.until != null && dayInWeek.isAfter(rule.until!)) continue;
          // Không sinh trước thời điểm bắt đầu gốc.
          if (dayInWeek.isBefore(baseStart)) continue;
          addInstanceAt(dayInWeek);
        }
      } else {
        addInstanceAt(occurrence);
      }

      generated++;
      period++;
      // Nếu đã vượt xa cuối cửa sổ thì dừng sớm (không cần sinh thêm).
      if (occurrence.isAfter(windowEnd) && rule.count == null) {
        break;
      }
    }
  }

  // RDATE: các ngày rời được thêm thủ công.
  for (final rd in _collectRDates(event.recurrence)) {
    addInstanceAt(rd);
  }

  results.sort((a, b) => a.start.effective.compareTo(b.start.effective));
  return results;
}

/// Tạo một instance mới của [event] tại [startDt]/[endDt], giữ nguyên nội dung
/// (tiêu đề, màu, mô tả...) nhưng KHÔNG mang recurrence (đây là một lần cụ thể).
CalendarEvent _instanceAt(
    CalendarEvent event, DateTime startDt, DateTime endDt) {
  final allDay = event.isAllDay;
  final newStart = allDay
      ? EventDateTime(date: DateTime(startDt.year, startDt.month, startDt.day),
          timeZone: event.start.timeZone)
      : EventDateTime(dateTime: startDt, timeZone: event.start.timeZone);
  final newEnd = allDay
      ? EventDateTime(date: DateTime(endDt.year, endDt.month, endDt.day),
          timeZone: event.end.timeZone)
      : EventDateTime(dateTime: endDt, timeZone: event.end.timeZone);

  return event.copyWith(
    id: '${event.id}#${startDt.millisecondsSinceEpoch}',
    start: newStart,
    end: newEnd,
    recurrence: const [],
    recurringEventId: event.id,
    originalStartTime: event.start,
  );
}

bool _overlapsWindow(
    DateTime start, DateTime end, DateTime windowStart, DateTime windowEnd) {
  return start.isBefore(windowEnd) && end.isAfter(windowStart);
}

/// Dịch [from] tới ngày trong tuần [weekday] (1=Mon..7=Sun) của TUẦN chứa
/// [from], giữ nguyên giờ/phút.
DateTime _shiftToWeekday(DateTime from, int weekday) {
  final delta = weekday - from.weekday;
  final d = from.add(Duration(days: delta));
  return DateTime(d.year, d.month, d.day, from.hour, from.minute, from.second);
}

bool _isExcluded(DateTime dt, List<DateTime> exDates) {
  for (final ex in exDates) {
    if (ex.year == dt.year &&
        ex.month == dt.month &&
        ex.day == dt.day &&
        ex.hour == dt.hour &&
        ex.minute == dt.minute) {
      return true;
    }
    // So khớp theo ngày cho EXDATE dạng chỉ-ngày.
    if (ex.hour == 0 && ex.minute == 0 && ex.second == 0 &&
        ex.year == dt.year && ex.month == dt.month && ex.day == dt.day) {
      return true;
    }
  }
  return false;
}

List<DateTime> _collectExDates(List<String> recurrence) =>
    _collectDates(recurrence, 'EXDATE');

List<DateTime> _collectRDates(List<String> recurrence) =>
    _collectDates(recurrence, 'RDATE');

/// Đọc các dòng "PREFIX:date,date,..." (EXDATE/RDATE). Bỏ qua tham số như
/// ";VALUE=DATE" hay ";TZID=..." — chỉ lấy phần sau dấu ':'.
List<DateTime> _collectDates(List<String> recurrence, String prefix) {
  final out = <DateTime>[];
  for (final line in recurrence) {
    final upper = line.toUpperCase();
    if (!upper.startsWith(prefix)) continue;
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final values = line.substring(colon + 1).split(',');
    for (final v in values) {
      final dt = _parseIcalDate(v.trim());
      if (dt != null) out.add(dt);
    }
  }
  return out;
}

enum _Freq { none, daily, weekly, monthly, yearly }

/// Đại diện đã phân tích của một dòng RRULE.
class _RRule {
  _RRule({
    required this.freq,
    required this.interval,
    this.count,
    this.until,
    this.byDays = const [],
  });

  final _Freq freq;
  final int interval;
  final int? count;
  final DateTime? until;

  /// Thứ trong tuần (1=Mon..7=Sun) cho FREQ=WEEKLY;BYDAY=...
  final List<int> byDays;

  /// Lần xuất hiện thứ [period] (0 = lần gốc) tính TỪ mốc [base] theo
  /// FREQ/INTERVAL. Tính từ gốc thay vì dồn từng bước để MONTHLY/YEARLY neo
  /// đúng theo ngày gốc (không bị "trôi" khi tháng bị kẹp ngày).
  DateTime occurrenceFromBase(DateTime base, int period) {
    final n = period * interval;
    switch (freq) {
      case _Freq.daily:
        return base.add(Duration(days: n));
      case _Freq.weekly:
        return base.add(Duration(days: 7 * n));
      case _Freq.monthly:
        return _addMonths(base, n);
      case _Freq.yearly:
        return _addMonths(base, 12 * n);
      case _Freq.none:
        return base.add(Duration(days: n));
    }
  }

  /// Phân tích danh sách [recurrence], lấy dòng RRULE đầu tiên.
  static _RRule? parse(List<String> recurrence) {
    final line = recurrence.firstWhere(
      (r) => r.toUpperCase().startsWith('RRULE'),
      orElse: () => '',
    );
    if (line.isEmpty) return null;

    final colon = line.indexOf(':');
    final body = colon >= 0 ? line.substring(colon + 1) : line;
    final parts = body.split(';');

    var freq = _Freq.none;
    var interval = 1;
    int? count;
    DateTime? until;
    var byDays = <int>[];

    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final key = kv[0].trim().toUpperCase();
      final value = kv[1].trim();
      switch (key) {
        case 'FREQ':
          freq = _freqFromString(value);
          break;
        case 'INTERVAL':
          interval = int.tryParse(value) ?? 1;
          if (interval < 1) interval = 1;
          break;
        case 'COUNT':
          count = int.tryParse(value);
          break;
        case 'UNTIL':
          until = _parseIcalDate(value);
          break;
        case 'BYDAY':
          byDays = value
              .split(',')
              .map(_weekdayFromString)
              .whereType<int>()
              .toList();
          break;
      }
    }

    return _RRule(
      freq: freq,
      interval: interval,
      count: count,
      until: until,
      byDays: byDays,
    );
  }

  static _Freq _freqFromString(String v) {
    switch (v.toUpperCase()) {
      case 'DAILY':
        return _Freq.daily;
      case 'WEEKLY':
        return _Freq.weekly;
      case 'MONTHLY':
        return _Freq.monthly;
      case 'YEARLY':
        return _Freq.yearly;
      default:
        return _Freq.none;
    }
  }

  static int? _weekdayFromString(String v) {
    switch (v.trim().toUpperCase()) {
      case 'MO':
        return DateTime.monday;
      case 'TU':
        return DateTime.tuesday;
      case 'WE':
        return DateTime.wednesday;
      case 'TH':
        return DateTime.thursday;
      case 'FR':
        return DateTime.friday;
      case 'SA':
        return DateTime.saturday;
      case 'SU':
        return DateTime.sunday;
      default:
        return null;
    }
  }
}

/// Cộng [months] tháng vào [dt], kẹp ngày cho tháng ngắn (ví dụ 31/1 + 1 tháng
/// -> 28/2). Giữ nguyên giờ/phút/giây.
DateTime _addMonths(DateTime dt, int months) {
  final totalMonth = dt.month - 1 + months;
  final year = dt.year + (totalMonth ~/ 12);
  final month = totalMonth % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = dt.day <= lastDay ? dt.day : lastDay;
  return DateTime(year, month, day, dt.hour, dt.minute, dt.second);
}

/// Phân tích một mốc thời gian iCal: dạng "YYYYMMDD" (chỉ ngày), hoặc
/// "YYYYMMDDTHHMMSS" / "YYYYMMDDTHHMMSSZ" (có giờ, có thể ở UTC). Trả về null
/// nếu không hợp lệ. Ngoài ra chấp nhận ISO-8601 để linh hoạt.
DateTime? _parseIcalDate(String raw) {
  var v = raw.trim();
  if (v.isEmpty) return null;

  // Thử iCal nén trước (không có dấu '-' ':').
  final isUtc = v.endsWith('Z');
  if (isUtc) v = v.substring(0, v.length - 1);

  if (!v.contains('-') && !v.contains(':')) {
    // YYYYMMDD hoặc YYYYMMDDTHHMMSS
    try {
      final year = int.parse(v.substring(0, 4));
      final month = int.parse(v.substring(4, 6));
      final day = int.parse(v.substring(6, 8));
      if (v.length >= 15 && v[8].toUpperCase() == 'T') {
        final hour = int.parse(v.substring(9, 11));
        final minute = int.parse(v.substring(11, 13));
        final second = int.parse(v.substring(13, 15));
        final dt = isUtc
            ? DateTime.utc(year, month, day, hour, minute, second).toLocal()
            : DateTime(year, month, day, hour, minute, second);
        return dt;
      }
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Dự phòng: ISO-8601.
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}
