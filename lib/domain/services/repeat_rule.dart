import 'dart:convert';

/// Kiểu lặp của một time interval.
enum RepeatFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case RepeatFrequency.none:
        return 'Không lặp lại';
      case RepeatFrequency.daily:
        return 'Hằng ngày';
      case RepeatFrequency.weekly:
        return 'Hằng tuần';
      case RepeatFrequency.monthly:
        return 'Hằng tháng';
      case RepeatFrequency.yearly:
        return 'Hằng năm';
    }
  }
}

/// Cách kết thúc chuỗi lặp.
enum RepeatEndMode {
  /// Không bao giờ kết thúc (ta vẫn giới hạn cứng để tránh sinh vô hạn).
  never,

  /// Kết thúc vào một ngày cụ thể.
  onDate,

  /// Kết thúc sau một số lần lặp.
  afterOccurrences,
}

/// Quy tắc lặp cho time interval.
///
/// Cách tiếp cận: một time interval lặp = NHIỀU time interval độc lập, mỗi cái
/// tại một ngày bắt đầu khác nhau. [generateStartDates] tính ra danh sách các
/// ngày bắt đầu (bao gồm cả ngày gốc). Nhờ vậy không cần thêm cột DB nào — mỗi
/// occurrence được lưu như một time interval bình thường (chỉnh/xóa riêng được).
class RepeatRule {
  const RepeatRule({
    this.frequency = RepeatFrequency.none,
    this.interval = 1,
    this.weekdays = const {},
    this.endMode = RepeatEndMode.never,
    this.endDate,
    this.occurrences = 1,
  });

  /// Không lặp.
  static const RepeatRule none = RepeatRule();

  final RepeatFrequency frequency;

  /// Lặp mỗi [interval] đơn vị (ví dụ mỗi 2 tuần).
  final int interval;

  /// Với lặp hằng tuần: tập các thứ trong tuần cần lặp (dùng weekday của Dart:
  /// Mon=1 ... Sun=7). Nếu rỗng, dùng đúng thứ của ngày gốc.
  final Set<int> weekdays;

  final RepeatEndMode endMode;

  /// Ngày kết thúc (khi [endMode] == onDate).
  final DateTime? endDate;

  /// Tổng số lần lặp gồm cả occurrence gốc (khi [endMode] == afterOccurrences).
  final int occurrences;

  bool get isRepeating => frequency != RepeatFrequency.none;

  /// Trần số occurrence tuyệt đối — lưới an toàn để không bao giờ sinh danh sách
  /// quá lớn (ví dụ lặp hằng ngày "không giới hạn"), tránh nặng bộ nhớ/DB.
  static const int _maxOccurrences = 1000;

  /// Mốc thời gian dừng CỨNG cho mọi kiểu lặp: không tạo occurrence nào có ngày
  /// bắt đầu sau thời điểm này. Kể cả khi người dùng chọn "không giới hạn", chuỗi
  /// lặp vẫn dừng ở đây. Đặt cuối năm 2100.
  static final DateTime hardEndDate = DateTime(2100, 12, 31);

  RepeatRule copyWith({
    RepeatFrequency? frequency,
    int? interval,
    Set<int>? weekdays,
    RepeatEndMode? endMode,
    DateTime? endDate,
    bool clearEndDate = false,
    int? occurrences,
  }) {
    return RepeatRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      endMode: endMode ?? this.endMode,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      occurrences: occurrences ?? this.occurrences,
    );
  }

  /// Sinh danh sách ngày BẮT ĐẦU cho tất cả các occurrence, tính từ [start].
  ///
  /// Luôn bao gồm chính [start] làm occurrence đầu tiên. Trả về danh sách chỉ
  /// gồm phần ngày (không giờ) — bên gọi sẽ ghép lại giờ gốc.
  List<DateTime> generateStartDates(DateTime start) {
    // Chuẩn hóa về nửa đêm để tính theo ngày.
    final base = DateTime(start.year, start.month, start.day);

    if (!isRepeating) return [base];

    final safeInterval = interval < 1 ? 1 : interval;
    final result = <DateTime>[];

    // Hàm kiểm tra đã tới điều kiện dừng chưa.
    bool reachedLimit(DateTime candidate, int countSoFar) {
      // Trần số lượng tuyệt đối (an toàn).
      if (result.length >= _maxOccurrences) return true;
      // Mốc dừng cứng theo thời gian — áp dụng cho MỌI kiểu kết thúc, kể cả
      // "không giới hạn".
      if (candidate.isAfter(hardEndDate)) return true;
      switch (endMode) {
        case RepeatEndMode.never:
          return false;
        case RepeatEndMode.onDate:
          if (endDate == null) return false;
          final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
          return candidate.isAfter(end);
        case RepeatEndMode.afterOccurrences:
          return countSoFar >= (occurrences < 1 ? 1 : occurrences);
      }
    }

    switch (frequency) {
      case RepeatFrequency.none:
        return [base];

      case RepeatFrequency.daily:
        var current = base;
        while (!reachedLimit(current, result.length)) {
          result.add(current);
          current = current.add(Duration(days: safeInterval));
        }
        break;

      case RepeatFrequency.weekly:
        // Nếu người dùng chọn các thứ cụ thể thì lặp theo chúng; nếu không,
        // dùng đúng thứ của ngày gốc.
        final days = weekdays.isNotEmpty ? weekdays : {base.weekday};
        // Bắt đầu từ đầu tuần chứa ngày gốc (Thứ Hai).
        var weekStart = base.subtract(Duration(days: base.weekday - 1));
        var stop = false;
        while (!stop) {
          // Duyệt các thứ trong tuần hiện tại theo thứ tự.
          final sortedDays = days.toList()..sort();
          for (final wd in sortedDays) {
            final candidate = weekStart.add(Duration(days: wd - 1));
            // Bỏ qua các ngày trước ngày gốc.
            if (candidate.isBefore(base)) continue;
            if (reachedLimit(candidate, result.length)) {
              stop = true;
              break;
            }
            result.add(candidate);
          }
          if (result.length >= _maxOccurrences) break;
          weekStart = weekStart.add(Duration(days: 7 * safeInterval));
        }
        break;

      case RepeatFrequency.monthly:
        var count = 0;
        while (true) {
          final candidate = _addMonths(base, count * safeInterval);
          if (reachedLimit(candidate, result.length)) break;
          result.add(candidate);
          count++;
        }
        break;

      case RepeatFrequency.yearly:
        var count = 0;
        while (true) {
          final candidate = DateTime(
              base.year + count * safeInterval, base.month, base.day);
          if (reachedLimit(candidate, result.length)) break;
          result.add(candidate);
          count++;
        }
        break;
    }

    // Đảm bảo luôn có ít nhất occurrence gốc.
    if (result.isEmpty) result.add(base);
    return result;
  }

  // ------------------------------------------------------------------
  // SERIALIZATION (Phase H1 — habit recurrence is stored as JSON)
  // ------------------------------------------------------------------

  /// JSON-able map. `weekdays` is sorted, `endDate` is a local day
  /// `yyyy-MM-dd` (wall-clock, no time zone).
  Map<String, dynamic> toMap() => {
        'frequency': frequency.name,
        'interval': interval,
        'weekdays': weekdays.toList()..sort(),
        'endMode': endMode.name,
        'endDate': endDate == null ? null : _formatDay(endDate!),
        'occurrences': occurrences,
      };

  String toJson() => jsonEncode(toMap());

  /// Tolerant reader: unknown / missing values fall back to the defaults, so a
  /// rule written by a newer build never breaks an older one.
  factory RepeatRule.fromMap(Map<String, dynamic> map) {
    T pick<T extends Enum>(List<T> values, Object? raw, T fallback) {
      for (final v in values) {
        if (v.name == raw) return v;
      }
      return fallback;
    }

    final rawWeekdays = map['weekdays'];
    final weekdays = <int>{
      if (rawWeekdays is List)
        for (final w in rawWeekdays)
          if (w is int && w >= 1 && w <= 7) w,
    };
    final rawInterval = map['interval'];
    final rawOcc = map['occurrences'];
    final rawEnd = map['endDate'];
    return RepeatRule(
      frequency:
          pick(RepeatFrequency.values, map['frequency'], RepeatFrequency.none),
      interval: rawInterval is int && rawInterval >= 1 ? rawInterval : 1,
      weekdays: weekdays,
      endMode: pick(RepeatEndMode.values, map['endMode'], RepeatEndMode.never),
      endDate: rawEnd == null ? null : DateTime.tryParse(rawEnd.toString()),
      occurrences: rawOcc is int && rawOcc >= 1 ? rawOcc : 1,
    );
  }

  /// Parse [toJson] output; null / corrupt JSON → [RepeatRule.none].
  static RepeatRule fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return RepeatRule.none;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return RepeatRule.fromMap(decoded.cast<String, dynamic>());
      }
    } catch (_) {}
    return RepeatRule.none;
  }

  // ------------------------------------------------------------------
  // DAY-BASED QUERIES (Phase H1). Pure calendar arithmetic on local days
  // (DST-safe: never adds Durations). Same semantics as
  // [generateStartDates] (weekly weeks start Monday, monthly clamps to the
  // last valid day, yearly uses DateTime normalization) but WITHOUT the
  // 1000-occurrence cap, which a long-running daily habit would hit.
  // ------------------------------------------------------------------

  /// True if [day] matches the repeat pattern anchored at [anchor], ignoring
  /// end conditions (onDate / afterOccurrences / [hardEndDate]).
  bool matchesPattern(DateTime anchor, DateTime day) {
    final a = _day(anchor);
    final d = _day(day);
    if (d.isBefore(a)) return false;
    final step = interval < 1 ? 1 : interval;
    switch (frequency) {
      case RepeatFrequency.none:
        return d == a;
      case RepeatFrequency.daily:
        return dayDiff(a, d) % step == 0;
      case RepeatFrequency.weekly:
        final days = weekdays.isNotEmpty ? weekdays : {a.weekday};
        if (!days.contains(d.weekday)) return false;
        final mondayA = DateTime(a.year, a.month, a.day - (a.weekday - 1));
        final mondayD = DateTime(d.year, d.month, d.day - (d.weekday - 1));
        return (dayDiff(mondayA, mondayD) ~/ 7) % step == 0;
      case RepeatFrequency.monthly:
        final months = (d.year - a.year) * 12 + d.month - a.month;
        if (months % step != 0) return false;
        final lastDay = DateTime(d.year, d.month + 1, 0).day;
        return d.day == (a.day <= lastDay ? a.day : lastDay);
      case RepeatFrequency.yearly:
        final years = d.year - a.year;
        if (years % step != 0) return false;
        return _day(DateTime(d.year, a.month, a.day)) == d;
    }
  }

  /// All local days in `[from, to]` (inclusive, date-only) on which the rule
  /// anchored at [anchor] occurs, applying every end condition. Walks forward
  /// from [anchor] one calendar day at a time (needed for afterOccurrences).
  List<DateTime> occurrencesBetween(
      DateTime anchor, DateTime from, DateTime to) {
    final a = _day(anchor);
    var last = _day(to);
    if (last.isAfter(hardEndDate)) last = _day(hardEndDate);
    if (endMode == RepeatEndMode.onDate && endDate != null) {
      final end = _day(endDate!);
      if (end.isBefore(last)) last = end;
    }
    final first = _day(from);
    final maxCount = occurrences < 1 ? 1 : occurrences;
    final result = <DateTime>[];
    var count = 0;
    for (var d = a; !d.isAfter(last); d = DateTime(d.year, d.month, d.day + 1)) {
      if (!matchesPattern(a, d)) continue;
      count++;
      if (endMode == RepeatEndMode.afterOccurrences && count > maxCount) break;
      if (!d.isBefore(first)) result.add(d);
      if (frequency == RepeatFrequency.none) break;
    }
    return result;
  }

  /// True if the rule anchored at [anchor] occurs on [day].
  bool occursOn(DateTime anchor, DateTime day) =>
      occurrencesBetween(anchor, day, day).isNotEmpty;

  /// Whole calendar days from [a] to [b] (local days, DST-safe).
  static int dayDiff(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _formatDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RepeatRule) return false;
    final sameEnd = (endDate == null && other.endDate == null) ||
        (endDate != null &&
            other.endDate != null &&
            _day(endDate!) == _day(other.endDate!));
    return other.frequency == frequency &&
        other.interval == interval &&
        other.weekdays.length == weekdays.length &&
        other.weekdays.containsAll(weekdays) &&
        other.endMode == endMode &&
        sameEnd &&
        other.occurrences == occurrences;
  }

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        Object.hashAllUnordered(weekdays),
        endMode,
        endDate == null ? null : _day(endDate!),
        occurrences,
      );

  @override
  String toString() => 'RepeatRule(${toJson()})';

  /// Cộng thêm [months] tháng vào [date], xử lý tràn ngày (ví dụ 31/1 + 1 tháng
  /// -> 28/2) bằng cách kẹp về ngày cuối cùng hợp lệ của tháng đích.
  static DateTime _addMonths(DateTime date, int months) {
    final totalMonth = date.month - 1 + months;
    final year = date.year + (totalMonth ~/ 12);
    final month = totalMonth % 12 + 1;
    // Số ngày của tháng đích.
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day <= lastDay ? date.day : lastDay;
    return DateTime(year, month, day);
  }
}
