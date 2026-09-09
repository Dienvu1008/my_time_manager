import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/focus_repository.dart';
import '../data/model_focus_session.dart';
import '../data/notification_service.dart';
import 'pomodoro_config.dart';

/// Bộ phát nhịp mỗi giây, đếm ngược từ [ticks] về 0.
class Ticker {
  const Ticker();
  Stream<int> tick({required int ticks}) {
    return Stream.periodic(const Duration(seconds: 1), (x) => ticks - x - 1)
        .take(ticks);
  }
}

/// Trạng thái chạy của timer.
enum TimerStatus { initial, running, paused, completed }

// ----------------------------- STATE -----------------------------

class PomodoroState extends Equatable {
  const PomodoroState({
    required this.config,
    required this.phase,
    required this.status,
    required this.remainingSeconds,
    required this.completedFocusSessions,
    this.selectedTask,
  });

  /// Trạng thái khởi tạo mặc định (giai đoạn focus, chưa chạy).
  factory PomodoroState.initial(PomodoroConfig config) {
    return PomodoroState(
      config: config,
      phase: PomodoroPhase.focus,
      status: TimerStatus.initial,
      remainingSeconds: config.durationSecondsFor(PomodoroPhase.focus),
      completedFocusSessions: 0,
      selectedTask: null,
    );
  }

  final PomodoroConfig config;
  final PomodoroPhase phase;
  final TimerStatus status;
  final int remainingSeconds;

  /// Số phiên focus đã hoàn tất trong chu kỳ hiện tại (để biết khi nào nghỉ dài).
  final int completedFocusSessions;

  /// Task đang được chọn để focus (có thể null = không gắn task).
  final SelectedTask? selectedTask;

  /// Tổng số giây của giai đoạn hiện tại (để tính % tiến trình cho vòng tròn).
  int get totalSeconds => config.durationSecondsFor(phase);

  /// Tiến trình 0.0 -> 1.0 của giai đoạn hiện tại.
  double get progress {
    if (totalSeconds == 0) return 0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  /// Số giây đã trôi qua của giai đoạn hiện tại (đã focus/nghỉ được bao lâu).
  int get elapsedSeconds => totalSeconds - remainingSeconds;

  /// True nếu timer đang chạy hoặc tạm dừng (tức có một phiên đang diễn ra).
  bool get isActive =>
      status == TimerStatus.running || status == TimerStatus.paused;

  PomodoroState copyWith({
    PomodoroConfig? config,
    PomodoroPhase? phase,
    TimerStatus? status,
    int? remainingSeconds,
    int? completedFocusSessions,
    SelectedTask? selectedTask,
    bool clearSelectedTask = false,
  }) {
    return PomodoroState(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
      selectedTask:
          clearSelectedTask ? null : (selectedTask ?? this.selectedTask),
    );
  }

  @override
  List<Object?> get props => [
        config,
        phase,
        status,
        remainingSeconds,
        completedFocusSessions,
        selectedTask,
      ];
}

// ----------------------------- EVENTS -----------------------------

sealed class PomodoroEvent extends Equatable {
  const PomodoroEvent();
  @override
  List<Object?> get props => [];
}

/// Bắt đầu (hoặc bắt đầu lại) giai đoạn hiện tại.
class PomodoroStarted extends PomodoroEvent {
  const PomodoroStarted();
}

class PomodoroPaused extends PomodoroEvent {
  const PomodoroPaused();
}

class PomodoroResumed extends PomodoroEvent {
  const PomodoroResumed();
}

/// Đặt lại giai đoạn hiện tại về đầu (không đổi phase).
class PomodoroReset extends PomodoroEvent {
  const PomodoroReset();
}

/// Bỏ qua giai đoạn hiện tại, chuyển sang giai đoạn kế tiếp.
class PomodoroSkipped extends PomodoroEvent {
  const PomodoroSkipped();
}

/// Chọn task để focus (null = bỏ chọn).
class PomodoroTaskSelected extends PomodoroEvent {
  const PomodoroTaskSelected(this.task);
  final SelectedTask? task;
  @override
  List<Object?> get props => [task];
}

/// Cập nhật cấu hình thời lượng.
class PomodoroConfigChanged extends PomodoroEvent {
  const PomodoroConfigChanged(this.config);
  final PomodoroConfig config;
  @override
  List<Object?> get props => [config];
}

/// Dừng hẳn phiên hiện tại (dùng khi kéo pop-up vào vùng X). Nếu [countTime]
/// true và đang ở giai đoạn focus, phần thời gian đã focus dở dang được lưu vào
/// tổng (một FocusSession với completed=false). Sau đó timer về trạng thái đầu.
class PomodoroStoppedWithChoice extends PomodoroEvent {
  const PomodoroStoppedWithChoice({required this.countTime});
  final bool countTime;
  @override
  List<Object?> get props => [countTime];
}

/// Sự kiện nội bộ: mỗi tick đồng hồ.
class _PomodoroTicked extends PomodoroEvent {
  const _PomodoroTicked(this.remaining);
  final int remaining;
  @override
  List<Object?> get props => [remaining];
}

// ----------------------------- BLOC -----------------------------

class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  PomodoroBloc({
    required FocusRepository repository,
    NotificationService? notificationService,
    Ticker ticker = const Ticker(),
    PomodoroConfig config = const PomodoroConfig(),
  })  : _repository = repository,
        _notifications = notificationService ?? NotificationService.instance,
        _ticker = ticker,
        super(PomodoroState.initial(config)) {
    on<PomodoroStarted>(_onStarted);
    on<PomodoroPaused>(_onPaused);
    on<PomodoroResumed>(_onResumed);
    on<PomodoroReset>(_onReset);
    on<PomodoroSkipped>(_onSkipped);
    on<PomodoroTaskSelected>(_onTaskSelected);
    on<PomodoroConfigChanged>(_onConfigChanged);
    on<PomodoroStoppedWithChoice>(_onStoppedWithChoice);
    on<_PomodoroTicked>(_onTicked);
  }

  final FocusRepository _repository;
  final NotificationService _notifications;
  final Ticker _ticker;

  StreamSubscription<int>? _tickerSubscription;

  /// Thời điểm bắt đầu giai đoạn focus hiện tại, để tính thời lượng session.
  DateTime? _phaseStartTime;

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  void _onStarted(PomodoroStarted event, Emitter<PomodoroState> emit) {
    _phaseStartTime = DateTime.now();
    emit(state.copyWith(status: TimerStatus.running));
    _startTicker(state.remainingSeconds);
  }

  void _startTicker(int from) {
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: from)
        .listen((remaining) => add(_PomodoroTicked(remaining)));
  }

  void _onPaused(PomodoroPaused event, Emitter<PomodoroState> emit) {
    if (state.status == TimerStatus.running) {
      _tickerSubscription?.pause();
      emit(state.copyWith(status: TimerStatus.paused));
    }
  }

  void _onResumed(PomodoroResumed event, Emitter<PomodoroState> emit) {
    if (state.status == TimerStatus.paused) {
      _tickerSubscription?.resume();
      emit(state.copyWith(status: TimerStatus.running));
    }
  }

  void _onReset(PomodoroReset event, Emitter<PomodoroState> emit) {
    _tickerSubscription?.cancel();
    _phaseStartTime = null;
    emit(state.copyWith(
      status: TimerStatus.initial,
      remainingSeconds: state.totalSeconds,
    ));
  }

  /// Dừng hẳn phiên (từ thao tác kéo pop-up vào vùng X).
  Future<void> _onStoppedWithChoice(
      PomodoroStoppedWithChoice event, Emitter<PomodoroState> emit) async {
    _tickerSubscription?.cancel();

    // Nếu người dùng muốn tính giờ VÀ đang ở giai đoạn focus có thời gian đã
    // trôi qua > 0, lưu một phiên "dở dang" (completed=false) với đúng số giây
    // đã focus thực tế.
    final elapsed = state.elapsedSeconds;
    if (event.countTime &&
        state.phase == PomodoroPhase.focus &&
        elapsed > 0) {
      await _saveFocusSession(
        completed: false,
        durationSecondsOverride: elapsed,
      );
    }

    _phaseStartTime = null;
    // Về trạng thái đầu của giai đoạn focus.
    emit(state.copyWith(
      phase: PomodoroPhase.focus,
      status: TimerStatus.initial,
      remainingSeconds: state.config.durationSecondsFor(PomodoroPhase.focus),
    ));
  }

  /// Bỏ qua giai đoạn hiện tại và chuyển sang giai đoạn kế tiếp mà KHÔNG lưu
  /// session (vì chưa hoàn tất focus).
  void _onSkipped(PomodoroSkipped event, Emitter<PomodoroState> emit) {
    _tickerSubscription?.cancel();
    _phaseStartTime = null;
    _moveToNextPhase(emit, focusCompleted: false);
  }

  void _onTaskSelected(
      PomodoroTaskSelected event, Emitter<PomodoroState> emit) {
    if (event.task == null) {
      emit(state.copyWith(clearSelectedTask: true));
    } else {
      emit(state.copyWith(selectedTask: event.task));
    }
  }

  void _onConfigChanged(
      PomodoroConfigChanged event, Emitter<PomodoroState> emit) {
    // Đổi cấu hình chỉ có ý nghĩa khi đang ở trạng thái chờ. Cập nhật luôn thời
    // gian còn lại của giai đoạn hiện tại theo cấu hình mới.
    _tickerSubscription?.cancel();
    emit(state.copyWith(
      config: event.config,
      status: TimerStatus.initial,
      remainingSeconds: event.config.durationSecondsFor(state.phase),
    ));
  }

  Future<void> _onTicked(
      _PomodoroTicked event, Emitter<PomodoroState> emit) async {
    if (event.remaining > 0) {
      emit(state.copyWith(remainingSeconds: event.remaining));
      return;
    }

    // Hết giờ giai đoạn hiện tại.
    final finishedPhase = state.phase;

    // Nếu là giai đoạn focus, lưu lại session vào repository.
    if (finishedPhase == PomodoroPhase.focus) {
      await _saveFocusSession(completed: true);
    }

    // Phát thông báo phù hợp với giai đoạn vừa kết thúc.
    await _notifyPhaseComplete(finishedPhase);

    // Chuyển sang giai đoạn kế tiếp và dừng ở trạng thái completed để UI hiện
    // dialog (desktop) / cho người dùng bấm bắt đầu giai đoạn mới.
    _moveToNextPhase(emit,
        focusCompleted: finishedPhase == PomodoroPhase.focus,
        markCompleted: true);
  }

  /// Tính giai đoạn kế tiếp và cập nhật state.
  void _moveToNextPhase(
    Emitter<PomodoroState> emit, {
    required bool focusCompleted,
    bool markCompleted = false,
  }) {
    var completed = state.completedFocusSessions;
    PomodoroPhase next;

    if (state.phase == PomodoroPhase.focus) {
      if (focusCompleted) completed += 1;
      // Sau đủ số phiên focus thì nghỉ dài, ngược lại nghỉ ngắn.
      final needLongBreak =
          completed > 0 && completed % state.config.sessionsBeforeLongBreak == 0;
      next = needLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      // Sau khi nghỉ (ngắn/dài) thì quay lại focus.
      next = PomodoroPhase.focus;
    }

    emit(state.copyWith(
      phase: next,
      status: markCompleted ? TimerStatus.completed : TimerStatus.initial,
      remainingSeconds: state.config.durationSecondsFor(next),
      completedFocusSessions: completed,
    ));
  }

  /// Lưu một phiên focus vào repository (local-first + sync).
  ///
  /// [durationSecondsOverride] cho phép lưu số giây focus thực tế (dùng khi
  /// dừng dở dang); nếu null thì dùng trọn thời lượng cấu hình của giai đoạn.
  Future<void> _saveFocusSession({
    required bool completed,
    int? durationSecondsOverride,
  }) async {
    final start = _phaseStartTime ?? DateTime.now();
    final end = DateTime.now();
    final selected = state.selectedTask;

    final session = FocusSession(
      taskType: selected?.type ?? FocusTaskType.none,
      taskId: selected?.id,
      taskTitle: selected?.title ?? '',
      startTime: start,
      endTime: end,
      focusDurationSeconds:
          durationSecondsOverride ?? state.config.focusMinutes * 60,
      completed: completed,
    );

    await _repository.saveSession(session);
    _phaseStartTime = null;
  }

  Future<void> _notifyPhaseComplete(PomodoroPhase finishedPhase) async {
    final String title;
    final String body;
    if (finishedPhase == PomodoroPhase.focus) {
      title = 'Hoàn thành phiên tập trung!';
      body = 'Làm tốt lắm. Đã đến giờ nghỉ ngơi một chút.';
    } else {
      title = 'Hết giờ nghỉ';
      body = 'Sẵn sàng cho phiên tập trung tiếp theo chưa?';
    }
    await _notifications.notifyPhaseComplete(title: title, body: body);
  }
}
