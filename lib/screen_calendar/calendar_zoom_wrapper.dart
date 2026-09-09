import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bọc một view lịch (day/week/month) và cung cấp khả năng phóng to/thu nhỏ.
///
/// Cách điều khiển:
/// - Chụm/mở hai ngón tay (pinch) — trên màn hình cảm ứng.
/// - Giữ Ctrl và cuộn chuột — trên desktop.
/// - Nút +/- nổi ở góc (có thể tắt qua [showButtons]).
///
/// [builder] nhận hệ số zoom hiện tại (1.0 = mặc định) và dựng view tương ứng.
/// Widget cha quyết định cách áp dụng hệ số (ví dụ nhân với heightPerMinute cho
/// day/week, hoặc chia cellAspectRatio cho month).
class CalendarZoomWrapper extends StatefulWidget {
  const CalendarZoomWrapper({
    super.key,
    required this.builder,
    this.showButtons = true,
    this.minZoom = 1.0,
    this.maxZoom = 4.0,
    this.initialZoom = 1.0,
  });

  /// Dựng nội dung theo hệ số zoom hiện tại và chiều cao khả dụng.
  ///
  /// [availableHeight] là chiều cao thực tế mà view có thể chiếm. Widget cha
  /// dùng nó để tính mức "vừa khít màn hình" ứng với zoom = 1.0 (mức nhỏ nhất).
  final Widget Function(
      BuildContext context, double zoom, double availableHeight) builder;

  /// Có hiển thị nút +/- hay không.
  final bool showButtons;

  final double minZoom;
  final double maxZoom;
  final double initialZoom;

  @override
  State<CalendarZoomWrapper> createState() => _CalendarZoomWrapperState();
}

class _CalendarZoomWrapperState extends State<CalendarZoomWrapper> {
  late double _zoom = widget.initialZoom;

  // Giá trị zoom tại thời điểm bắt đầu pinch, để nhân với scale tương đối.
  double _zoomAtGestureStart = 1.0;

  void _setZoom(double value) {
    final clamped = value.clamp(widget.minZoom, widget.maxZoom);
    if (clamped != _zoom) {
      setState(() => _zoom = clamped);
    }
  }

  /// Bước phóng to/thu nhỏ khi bấm nút hoặc cuộn chuột.
  void _zoomBy(double factor) => _setZoom(_zoom * factor);

  bool get _isCtrlPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    // Ctrl + cuộn chuột = zoom (giống trình duyệt/trình soạn thảo).
    if (event is PointerScrollEvent && _isCtrlPressed) {
      // Cuộn lên (dy < 0) -> phóng to; cuộn xuống -> thu nhỏ.
      final factor = event.scrollDelta.dy < 0 ? 1.1 : (1 / 1.1);
      _zoomBy(factor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Nghe tín hiệu con lăn chuột để xử lý Ctrl+cuộn. Listener không tham gia
      // gesture arena nên không ảnh hưởng cuộn/chạm bình thường của lịch.
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        // Chỉ xử lý khi pinch bằng 2 ngón; scale=1.0 với 1 ngón được bỏ qua để
        // không chặn thao tác cuộn/chạm của lịch.
        onScaleStart: (details) {
          if (details.pointerCount >= 2) {
            _zoomAtGestureStart = _zoom;
          }
        },
        onScaleUpdate: (details) {
          if (details.pointerCount >= 2) {
            _setZoom(_zoomAtGestureStart * details.scale);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Chiều cao khả dụng để widget cha tính mức "vừa khít".
                  final availableHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height;
                  return widget.builder(context, _zoom, availableHeight);
                },
              ),
            ),
            if (widget.showButtons)
              Positioned(
                right: 12,
                bottom: 12,
                child: _ZoomButtons(
                  onZoomIn: () => _zoomBy(1.2),
                  onZoomOut: () => _zoomBy(1 / 1.2),
                  onReset: () => _setZoom(1.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cụm nút +/- và nút đặt lại zoom.
class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Phóng to',
            onPressed: onZoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Đặt lại',
            onPressed: onReset,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Thu nhỏ',
            onPressed: onZoomOut,
          ),
        ],
      ),
    );
  }
}
