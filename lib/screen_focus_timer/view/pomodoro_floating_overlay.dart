import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_config.dart';
import 'pomodoro_overlay_controller.dart';

/// Bọc toàn bộ app và vẽ một "cửa sổ nổi" (picture-in-picture) hiển thị thời
/// gian Pomodoro còn lại, nổi trên mọi màn hình.
///
/// Điều kiện hiển thị (đồng thời):
/// - Cài đặt "chạy nền" (AppState.keepPomodoroRunningInBackground) đang bật.
/// - Timer đang chạy hoặc tạm dừng (PomodoroState.isActive).
/// - Người dùng KHÔNG đang ở màn hình Pomodoro (isOnPomodoroScreen == false).
///
/// Tương tác:
/// - Chạm: mở màn hình Pomodoro.
/// - Kéo (pan): di chuyển bong bóng; trong lúc kéo hiện vùng "X" ở đáy. Thả bong
///   bóng vào vùng X để dừng đồng hồ, kèm dialog hỏi có tính phần thời gian đã
///   tập trung vào tổng hay không.
///
/// LƯU Ý KỸ THUẬT: cố tình KHÔNG dùng Draggable/DragTarget. Overlay này nằm
/// trong MaterialApp.builder (ngoài Navigator/Overlay chính), nơi Draggable
/// không hoạt động ổn định trên desktop (gây treo). Thay vào đó ta tự xử lý kéo
/// bằng GestureDetector + tính va chạm thủ công.
class PomodoroFloatingOverlay extends StatefulWidget {
  const PomodoroFloatingOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<PomodoroFloatingOverlay> createState() =>
      _PomodoroFloatingOverlayState();
}

class _PomodoroFloatingOverlayState extends State<PomodoroFloatingOverlay> {
  /// Vị trí góc trên-trái của bong bóng (toạ độ trong vùng overlay).
  Offset _position = const Offset(20, 100);

  /// Đang kéo bong bóng hay không (để hiện vùng X + phóng to vùng X khi tới gần).
  bool _dragging = false;

  /// Bong bóng có đang nằm trên vùng X hay không (để đổi màu vùng X).
  bool _overDeleteZone = false;

  static const double _bubbleSize = 76;
  static const double _deleteZoneSize = 72;
  static const double _deleteZoneBottomMargin = 48;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: BlocBuilder<AppBloc, AppState>(
            buildWhen: (p, c) =>
                p.keepPomodoroRunningInBackground !=
                c.keepPomodoroRunningInBackground,
            builder: (context, appState) {
              if (!appState.keepPomodoroRunningInBackground) {
                return const SizedBox.shrink();
              }
              return BlocBuilder<PomodoroBloc, PomodoroState>(
                builder: (context, pomoState) {
                  if (!pomoState.isActive) return const SizedBox.shrink();
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        PomodoroOverlayController.instance.isOnPomodoroScreen,
                    builder: (context, onScreen, _) {
                      if (onScreen) return const SizedBox.shrink();
                      return _buildOverlay(context, pomoState);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context, PomodoroState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Giữ bong bóng trong vùng hiển thị.
        final left =
            _position.dx.clamp(0.0, (maxW - _bubbleSize).clamp(0.0, maxW));
        final top =
            _position.dy.clamp(0.0, (maxH - _bubbleSize).clamp(0.0, maxH));

        // Tâm vùng X (dưới đáy, giữa ngang).
        final deleteCenter = Offset(
          maxW / 2,
          maxH - _deleteZoneBottomMargin - _deleteZoneSize / 2,
        );

        return Stack(
          children: [
            // Vùng "X" — chỉ hiện khi đang kéo.
            if (_dragging)
              Positioned(
                left: deleteCenter.dx - _deleteZoneSize / 2,
                top: deleteCenter.dy - _deleteZoneSize / 2,
                child: _buildDeleteZone(),
              ),
            // Bong bóng đồng hồ.
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    PomodoroOverlayController.instance.openPomodoro(),
                onPanStart: (_) => setState(() => _dragging = true),
                onPanUpdate: (details) {
                  setState(() {
                    _position = Offset(
                      _position.dx + details.delta.dx,
                      _position.dy + details.delta.dy,
                    );
                    // Kiểm tra tâm bong bóng có nằm trong vùng X không.
                    final bubbleCenter = Offset(
                      _position.dx + _bubbleSize / 2,
                      _position.dy + _bubbleSize / 2,
                    );
                    _overDeleteZone =
                        (bubbleCenter - deleteCenter).distance <
                            _deleteZoneSize;
                  });
                },
                onPanEnd: (_) => _onPanEnd(context, state),
                child: _bubble(context, state, dragging: _dragging),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onPanEnd(BuildContext context, PomodoroState state) {
    final wasOverDelete = _overDeleteZone;
    setState(() {
      _dragging = false;
      _overDeleteZone = false;
    });
    if (wasOverDelete) {
      _onDroppedOnDelete(context, state);
    }
  }

  /// Bong bóng hiển thị thời gian còn lại.
  Widget _bubble(BuildContext context, PomodoroState state,
      {bool dragging = false}) {
    final theme = Theme.of(context);
    final minutes = (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.remainingSeconds % 60).toString().padLeft(2, '0');
    final color = state.phase == PomodoroPhase.focus
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: _bubbleSize,
        height: _bubbleSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dragging ? 0.4 : 0.25),
              blurRadius: dragging ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              '$minutes:$seconds',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vùng "X" để dừng đồng hồ; phóng to + đổi màu đậm khi bong bóng ở trên nó.
  Widget _buildDeleteZone() {
    final active = _overDeleteZone;
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: active ? _deleteZoneSize + 12 : _deleteZoneSize,
        height: active ? _deleteZoneSize + 12 : _deleteZoneSize,
        decoration: BoxDecoration(
          color: active ? Colors.red : Colors.red.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 36),
      ),
    );
  }

  /// Khi thả bong bóng vào vùng X: hỏi có tính phần thời gian đã tập trung vào
  /// tổng hay không, rồi dừng đồng hồ.
  Future<void> _onDroppedOnDelete(
      BuildContext context, PomodoroState state) async {
    final bloc = context.read<PomodoroBloc>();

    // Chỉ hỏi khi đang ở giai đoạn focus và đã trôi qua ít nhất 1 giây; nếu
    // không thì dừng luôn, không cần tính giờ.
    final canCount =
        state.phase == PomodoroPhase.focus && state.elapsedSeconds > 0;

    if (!canCount) {
      bloc.add(const PomodoroStoppedWithChoice(countTime: false));
      return;
    }

    // Overlay nằm trong MaterialApp.builder (ngoài Navigator), nên context của
    // nó KHÔNG có Navigator -> phải dùng context của Navigator gốc để mở dialog.
    final navigatorContext =
        PomodoroOverlayController.instance.navigatorKey.currentContext;
    if (navigatorContext == null) {
      // Không mở được dialog -> dừng an toàn, không tính giờ.
      bloc.add(const PomodoroStoppedWithChoice(countTime: false));
      return;
    }

    final minutes = (state.elapsedSeconds / 60).round();
    final countTime = await showDialog<bool>(
      context: navigatorContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dừng phiên tập trung'),
        content: Text(
          'Bạn đã tập trung khoảng $minutes phút. '
          'Tính khoảng thời gian này vào tổng thời gian tập trung chứ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không tính'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Có, tính vào'),
          ),
        ],
      ),
    );

    // countTime == null nghĩa là người dùng đóng dialog -> vẫn dừng, không tính.
    bloc.add(PomodoroStoppedWithChoice(countTime: countTime ?? false));
  }
}
