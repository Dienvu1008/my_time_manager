import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vòng tròn tiến trình lớn (giống Windows 11 Focus Sessions).
///
/// Vẽ một vòng tròn nền mờ và một cung tô đậm thể hiện tiến trình [progress]
/// (0.0 -> 1.0). Ở giữa hiển thị [child] (thường là thời gian đếm ngược).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 280,
    this.strokeWidth = 14,
    this.color,
  });

  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringColor = color ?? theme.colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          foreground: ringColor,
          // Vòng nền dùng màu mờ để nổi bật ở cả sáng lẫn tối (dark mode).
          background: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.foreground,
    required this.background,
  });

  final double progress;
  final double strokeWidth;
  final Color foreground;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Vẽ vòng nền đầy đủ.
    canvas.drawCircle(center, radius, backgroundPaint);

    // Vẽ cung tiến trình, bắt đầu từ đỉnh (-90 độ) đi theo chiều kim đồng hồ.
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.foreground != foreground ||
        oldDelegate.background != background ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
