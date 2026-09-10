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
