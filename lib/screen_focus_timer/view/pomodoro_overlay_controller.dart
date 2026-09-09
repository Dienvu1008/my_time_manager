import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Điều phối cho cửa sổ nổi (PiP) của Pomodoro.
///
/// Giữ hai mẩu trạng thái toàn cục mà overlay cần nhưng không thuộc về bloc:
/// - [isOnPomodoroScreen]: có đang hiển thị màn hình Pomodoro hay không (để ẩn
///   overlay khi người dùng đang ở ngay màn đó).
/// - [openPomodoro]: hàm để "mở" màn hình Pomodoro khi người dùng chạm vào
///   overlay. Do việc điều hướng phụ thuộc layout (Home dùng drawer index,
///   hoặc route được push), phần điều hướng thật được đăng ký từ ngoài vào.
class PomodoroOverlayController {
  PomodoroOverlayController._();
  static final PomodoroOverlayController instance =
      PomodoroOverlayController._();

  /// Key của Navigator gốc (gắn vào MaterialApp.navigatorKey). Cửa sổ nổi nằm
  /// trong MaterialApp.builder (ngoài Navigator) nên khi cần hiện dialog phải
  /// dùng context của Navigator này thay vì context của overlay.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// True khi màn hình Pomodoro đang hiển thị (overlay sẽ ẩn).
  ///
  /// Dùng bộ đếm số instance PomodoroScreen đang mounted thay vì bool đơn, để
  /// tránh race khi rời rồi quay lại nhanh (dispose màn cũ và initState màn mới
  /// xen kẽ nhau). Overlay ẩn khi số instance > 0.
  final ValueNotifier<bool> isOnPomodoroScreen = ValueNotifier<bool>(false);

  int _screenCount = 0;

  /// Cập nhật [isOnPomodoroScreen] một cách AN TOÀN.
  ///
  /// [enterPomodoroScreen] thường được gọi từ `initState` của PomodoroScreen,
  /// mà initState có thể chạy NGAY trong phase build của widget cha (ví dụ khi
  /// màn Pomodoro được render inline trong Home). Đổi giá trị ValueNotifier lúc
  /// đó sẽ khiến ValueListenableBuilder (overlay) bị markNeedsBuild giữa lúc
  /// đang build -> ném lỗi. Vì vậy nếu đang trong lúc build/layout thì hoãn
  /// việc đổi giá trị sang sau frame; ngoài phase build thì đổi ngay.
  void _syncFlag() {
    final target = _screenCount > 0;
    if (isOnPomodoroScreen.value == target) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuilding = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.transientCallbacks;
    if (isBuilding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isOnPomodoroScreen.value = _screenCount > 0;
      });
    } else {
      isOnPomodoroScreen.value = target;
    }
  }

  /// Gọi khi một PomodoroScreen bắt đầu hiển thị.
  void enterPomodoroScreen() {
    _screenCount++;
    _syncFlag();
  }

  /// Gọi khi một PomodoroScreen rời đi.
  void leavePomodoroScreen() {
    if (_screenCount > 0) _screenCount--;
    _syncFlag();
  }

  /// Hàm điều hướng tới màn Pomodoro, do Home đăng ký (chuyển drawer index).
  /// Có thể null nếu chưa có ai đăng ký.
  VoidCallback? _openHandler;

  void registerOpenHandler(VoidCallback handler) {
    _openHandler = handler;
  }

  void unregisterOpenHandler(VoidCallback handler) {
    if (_openHandler == handler) _openHandler = null;
  }

  /// Yêu cầu mở màn hình Pomodoro (gọi khi chạm vào overlay).
  void openPomodoro() {
    _openHandler?.call();
  }
}
