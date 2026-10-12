import 'package:equatable/equatable.dart';

import '../../domain/models/model_focus_session.dart';

/// Giai đoạn hiện tại trong chu kỳ Pomodoro.
enum PomodoroPhase {
  /// Đang tập trung làm việc.
  focus,

  /// Nghỉ ngắn (sau mỗi phiên focus).
  shortBreak,

  /// Nghỉ dài (sau mỗi [PomodoroConfig.sessionsBeforeLongBreak] phiên focus).
  longBreak;

  String get label {
    switch (this) {
      case PomodoroPhase.focus:
        return 'Tập trung';
      case PomodoroPhase.shortBreak:
        return 'Nghỉ ngắn';
      case PomodoroPhase.longBreak:
        return 'Nghỉ dài';
    }
  }
}

/// Cấu hình thời lượng cho các giai đoạn Pomodoro (tính bằng phút).
///
/// Giá trị mặc định theo kỹ thuật Pomodoro cổ điển: 25 phút focus, nghỉ ngắn
/// 5 phút, nghỉ dài 15 phút sau mỗi 4 phiên.
class PomodoroConfig extends Equatable {
  const PomodoroConfig({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;

  /// Số giây cho một giai đoạn cụ thể.
  int durationSecondsFor(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return focusMinutes * 60;
      case PomodoroPhase.shortBreak:
        return shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return longBreakMinutes * 60;
    }
  }

  PomodoroConfig copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroConfig(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }

  @override
  List<Object?> get props => [
        focusMinutes,
        shortBreakMinutes,
        longBreakMinutes,
        sessionsBeforeLongBreak,
      ];
}

/// Thông tin task được chọn để focus (nhẹ, chỉ giữ những gì UI/bloc cần).
class SelectedTask extends Equatable {
  const SelectedTask({
    required this.type,
    required this.id,
    required this.title,
    this.isMeasurable = false,
    this.hasSubtasks = false,
  });

  final FocusTaskType type;
  final String id;
  final String title;

  /// Task là loại đo lường (chỉ dùng để hiển thị biểu tượng phù hợp).
  final bool isMeasurable;

  /// Task có công việc con (chỉ dùng để hiển thị biểu tượng phù hợp).
  final bool hasSubtasks;

  @override
  List<Object?> get props => [type, id, title, isMeasurable, hasSubtasks];
}
