import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/focus_repository.dart';
import '../../domain/models/model_focus_session.dart';

/// Khoảng thời gian thống kê.
enum StatsRange {
  daily('Hôm nay'),
  weekly('Tuần này'),
  monthly('Tháng này');

  const StatsRange(this.label);
  final String label;
}

/// Kết quả thống kê đã tổng hợp cho một khoảng thời gian.
class StatsState extends Equatable {
  const StatsState({
    this.range = StatsRange.daily,
    this.loading = true,
    this.totalFocusMinutes = 0,
    this.completedSessionCount = 0,
    this.partialSessionCount = 0,
    this.perTask = const [],
  });

  final StatsRange range;
  final bool loading;

  /// Tổng số phút focus trong khoảng (gồm cả phiên hoàn tất lẫn dở dang).
  final int totalFocusMinutes;

  /// Số phiên focus ĐÃ HOÀN TẤT (chạy hết giờ) trong khoảng.
  final int completedSessionCount;

  /// Số phiên focus DỞ DANG (bị dừng giữa chừng nhưng được tính giờ) trong khoảng.
  final int partialSessionCount;

  /// Tổng số phiên focus (hoàn tất + dở dang).
  int get totalSessionCount => completedSessionCount + partialSessionCount;

  /// Thống kê theo từng task: (tên task, tổng phút). Sắp theo phút giảm dần.
  final List<TaskStat> perTask;

  StatsState copyWith({
    StatsRange? range,
    bool? loading,
    int? totalFocusMinutes,
    int? completedSessionCount,
    int? partialSessionCount,
    List<TaskStat>? perTask,
  }) {
    return StatsState(
      range: range ?? this.range,
      loading: loading ?? this.loading,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      completedSessionCount:
          completedSessionCount ?? this.completedSessionCount,
      partialSessionCount: partialSessionCount ?? this.partialSessionCount,
      perTask: perTask ?? this.perTask,
    );
  }

  @override
  List<Object?> get props => [
        range,
        loading,
        totalFocusMinutes,
        completedSessionCount,
        partialSessionCount,
        perTask,
      ];
}

class TaskStat extends Equatable {
  const TaskStat({required this.title, required this.minutes});
  final String title;
  final int minutes;

  @override
  List<Object?> get props => [title, minutes];
}

/// Cubit tính thống kê focus theo ngày/tuần/tháng từ [FocusRepository].
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._repository) : super(const StatsState()) {
    load(StatsRange.daily);
  }

  final FocusRepository _repository;

  /// Tính khoảng [start, end) tương ứng với [range], mốc theo thời gian địa phương.
  ({DateTime start, DateTime end}) _rangeBounds(StatsRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (range) {
      case StatsRange.daily:
        return (start: today, end: today.add(const Duration(days: 1)));
      case StatsRange.weekly:
        // Tuần bắt đầu từ Thứ Hai (weekday: Mon=1..Sun=7).
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return (start: startOfWeek, end: startOfWeek.add(const Duration(days: 7)));
      case StatsRange.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
        return (start: startOfMonth, end: startOfNextMonth);
    }
  }

  Future<void> load(StatsRange range) async {
    emit(state.copyWith(range: range, loading: true));

    final bounds = _rangeBounds(range);
    final sessions =
        await _repository.sessionsBetween(bounds.start, bounds.end);

    // Tính TẤT CẢ phiên có trong khoảng, gồm cả phiên dở dang (completed=false)
    // được người dùng chọn "tính vào tổng" khi dừng giữa chừng. Thời lượng của
    // phiên dở dang đã được lưu đúng bằng số giây thực tế đã tập trung.
    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.focusDurationSeconds);

    var completedCount = 0;
    var partialCount = 0;
    // Gộp theo task (dùng taskTitle, hoặc "Không gắn task" nếu trống).
    final Map<String, int> byTask = {};
    for (final s in sessions) {
      if (s.completed) {
        completedCount++;
      } else {
        partialCount++;
      }
      final key = s.taskTitle.isEmpty ? FocusTaskType.none.label : s.taskTitle;
      byTask[key] = (byTask[key] ?? 0) + s.focusDurationSeconds;
    }
    final perTask = byTask.entries
        .map((e) => TaskStat(title: e.key, minutes: (e.value / 60).round()))
        .toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    emit(state.copyWith(
      loading: false,
      totalFocusMinutes: (totalSeconds / 60).round(),
      completedSessionCount: completedCount,
      partialSessionCount: partialCount,
      perTask: perTask,
    ));
  }
}
